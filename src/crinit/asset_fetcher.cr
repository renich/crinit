require "http/client"
require "uri"
require "colorize"

module Crinit
  # Implements the 4-tier smart fallback resolution pipeline for remote assets.
  class AssetFetcher
    getter config : Config
    getter template_dir : Path
    getter engine : TokenEngine
    getter cache : CacheStore

    MAX_ASSET_SIZE = 50 * 1024 * 1024 # 50 MiB

    def initialize(
      @config : Config,
      @template_dir : Path,
      @engine : TokenEngine,
      @cache : CacheStore = CacheStore.from_config(config),
    )
    end

    def resolve_all(assets : Array(RemoteAsset)) : Nil
      assets.each do |asset|
        resolve_asset(asset)
      end
    end

    def resolve_asset(asset : RemoteAsset) : Nil
      target_rel = engine.render_path(Path.new(asset.target))
      target_path = PathGuard.ensure_within!(
        config.expanded_dir,
        config.expanded_dir.join(target_rel),
        "remote asset target #{asset.target.inspect}"
      )

      is_overwrite = File.exists?(target_path)
      return if is_overwrite && config.skip_existing?

      Dir.mkdir_p(target_path.dirname)

      return if try_tier1_cache(asset, target_path, is_overwrite)
      return if try_tier2_download(asset, target_path, is_overwrite)
      return if try_tier3_fallback(asset, target_path, is_overwrite)

      create_tier4_stub(asset, target_path)
    end

    private def try_tier1_cache(asset : RemoteAsset, target_path : Path, is_overwrite : Bool) : Bool
      return false if config.refresh_assets?

      sha = asset.sha256
      return false unless sha

      if cached_file = cache.get(sha)
        copy_and_chmod(cached_file, target_path, asset)
        log_action("cache", target_path, is_overwrite)
        true
      else
        false
      end
    end

    private def try_tier2_download(asset : RemoteAsset, target_path : Path, is_overwrite : Bool) : Bool
      return false if config.offline?

      begin
        data = fetch_url_with_redirects(asset.url)

        if sha = asset.sha256
          verify_checksum!(data, sha, asset.url)
          cache.store(sha, data)
        end

        write_and_chmod(data, target_path, asset)
        log_action("download", target_path, is_overwrite)
        true
      rescue ex : SecurityError
        raise ex
      rescue ex : Exception
        unless config.silent?
          STDERR.puts "   #{"warning".colorize(:yellow)} Failed to download #{asset.url}: #{ex.message}"
        end
        false
      end
    end

    private def verify_checksum!(data : Bytes, expected_sha : String, url : String) : Nil
      computed_sha = CacheStore.digest(data)
      if computed_sha.downcase != expected_sha.downcase
        raise SecurityError.new(
          "Integrity verification failed for #{url}\n" \
          "  Expected SHA-256: #{expected_sha}\n" \
          "  Computed SHA-256: #{computed_sha}"
        )
      end
    end

    private def try_tier3_fallback(asset : RemoteAsset, target_path : Path, is_overwrite : Bool) : Bool
      fallback_rel = asset.fallback
      return false unless fallback_rel

      fallback_path = PathGuard.ensure_within!(
        template_dir,
        template_dir.join(fallback_rel),
        "fallback asset #{fallback_rel.inspect}"
      )
      return false unless File.exists?(fallback_path)

      copy_and_chmod(fallback_path, target_path, asset)
      log_action("fallback", target_path, is_overwrite)
      true
    end

    private def create_tier4_stub(asset : RemoteAsset, target_path : Path) : Nil
      stub_path = Path.new("#{target_path}.todo")
      todo_message = <<-TXT
        Asset could not be automatically fetched:
          URL: #{asset.url}
          Expected Target: #{target_path}
          Expected SHA-256: #{asset.sha256 || "none"}

        Please download this file manually and place it at:
          #{target_path}
        TXT
      File.write(stub_path, todo_message)
      log_action("stub", stub_path, false)

      unless config.silent?
        STDERR.puts "   #{"warning".colorize(:yellow)} Asset unavailable (#{asset.url}). Created placeholder: #{stub_path}"
      end
    end

    private def fetch_url_with_redirects(url : String, max_redirects : Int32 = 5) : Bytes
      raise AssetFetchError.new("Too many HTTP redirects for #{url}") if max_redirects <= 0

      uri = URI.parse(url)
      validate_url!(uri)

      HTTP::Client.new(uri) do |client|
        client.connect_timeout = 3.seconds
        client.read_timeout = 5.seconds

        client.get(uri.request_target) do |response|
          if response.status.redirection? && (location = response.headers["Location"]?)
            redirect_uri = URI.parse(location)
            target_url = redirect_uri.host ? location : uri.resolve(redirect_uri).to_s
            return fetch_url_with_redirects(target_url, max_redirects - 1)
          elsif response.status.success?
            memory_io = IO::Memory.new
            bytes_copied = IO.copy(response.body_io, memory_io, limit: MAX_ASSET_SIZE + 1)
            if bytes_copied > MAX_ASSET_SIZE
              raise SecurityError.new("Remote asset exceeds maximum allowed size (#{MAX_ASSET_SIZE} bytes): #{url}")
            end
            return memory_io.to_slice
          else
            raise AssetFetchError.new("HTTP status #{response.status_code} (#{response.status_message}) for #{url}")
          end
        end
      end
    rescue ex : Socket::Error | IO::TimeoutError
      raise AssetFetchError.new("Network failure fetching #{url}: #{ex.message}")
    end

    private def copy_and_chmod(source : Path, destination : Path, asset : RemoteAsset) : Nil
      File.copy(source, destination)
      apply_permissions(destination, asset)
    end

    private def write_and_chmod(data : Bytes, destination : Path, asset : RemoteAsset) : Nil
      File.write(destination, data)
      apply_permissions(destination, asset)
    end

    private def apply_permissions(destination : Path, asset : RemoteAsset) : Nil
      {% unless flag?(:windows) %}
        if asset.executable?
          File.chmod(destination, File::Permissions.new(0o755))
        end
      {% end %}
    end

    private def log_action(source_tag : String, path : Path, overwrite : Bool) : Nil
      return if config.silent?

      tag = "[#{source_tag}]".colorize(:cyan)
      verb = overwrite ? "overwrite".colorize(:light_green) : "create".colorize(:light_green)
      prefix = overwrite ? " " : "    "
      puts "#{prefix}#{verb} #{tag}  #{path}"
    end

    BLOCKED_METADATA_HOSTS = {"169.254.169.254", "metadata.google.internal", "instance-data"}

    private def validate_url!(uri : URI) : Nil
      scheme = uri.scheme
      unless scheme == "http" || scheme == "https"
        raise SecurityError.new("Insecure URI scheme: #{scheme.inspect}. Only HTTP and HTTPS are permitted.")
      end

      host = uri.host
      if host.nil? || host.empty?
        raise SecurityError.new("Invalid URI: Missing host in #{uri}")
      end

      if BLOCKED_METADATA_HOSTS.includes?(host.downcase)
        raise SecurityError.new("Access to internal/metadata address #{host.inspect} is prohibited.")
      end
    end
  end
end
