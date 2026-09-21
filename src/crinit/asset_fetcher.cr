require "http/client"
require "socket"
require "uri"
require "colorize"

module Crinit
  # Implements the 4-tier smart fallback resolution pipeline for remote assets.
  class AssetFetcher
    getter config : Config
    getter template_dir : Path
    getter engine : TokenEngine
    getter cache : CacheStore
    getter? allow_local : Bool

    MAX_ASSET_SIZE = 50 * 1024 * 1024 # 50 MiB

    def initialize(
      @config : Config,
      @template_dir : Path,
      @engine : TokenEngine,
      @cache : CacheStore = CacheStore.from_config(config),
      @allow_local : Bool = false,
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

      is_overwrite = File.exists?(target_path) || File.symlink?(target_path)
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

      if asset.executable? && asset.sha256.nil?
        raise SecurityError.new(
          "Remote executable asset #{asset.target} missing required sha256 checksum in template manifest"
        )
      end

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

      host_str = uri.host || raise SecurityError.new("Invalid URI: Missing host in #{uri}")
      port_num = uri.port || (uri.scheme == "https" ? 443 : 80)
      use_tls = uri.scheme == "https"

      HTTP::Client.new(host: host_str, port: port_num, tls: use_tls) do |client|
        client.connect_timeout = 3.seconds
        client.read_timeout = 5.seconds
        handle_client_request(client, uri, url, max_redirects)
      end
    rescue ex : Socket::Error | IO::TimeoutError
      raise AssetFetchError.new("Network failure fetching #{url}: #{ex.message}")
    end

    private def handle_client_request(
      client : HTTP::Client,
      uri : URI,
      url : String,
      max_redirects : Int32,
    ) : Bytes
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

    private def copy_and_chmod(source : Path, destination : Path, asset : RemoteAsset) : Nil
      File.delete(destination) if File.symlink?(destination)
      File.copy(source, destination)
      apply_permissions(destination, asset)
    end

    private def write_and_chmod(data : Bytes, destination : Path, asset : RemoteAsset) : Nil
      File.delete(destination) if File.symlink?(destination)
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

    BLOCKED_HOSTNAMES = {"169.254.169.254", "metadata.google.internal", "instance-data", "localhost"}

    private def validate_url!(uri : URI) : Nil
      scheme = uri.scheme
      unless scheme == "http" || scheme == "https"
        raise SecurityError.new("Insecure URI scheme: #{scheme.inspect}. Only HTTP and HTTPS are permitted.")
      end

      host = uri.host
      if host.nil? || host.empty?
        raise SecurityError.new("Invalid URI: Missing host in #{uri}")
      end

      return if allow_local?

      host_lower = host.downcase.strip("[]")
      if BLOCKED_HOSTNAMES.includes?(host_lower)
        raise SecurityError.new("Access to internal/metadata address #{host.inspect} is prohibited.")
      end

      if blocked_ip?(host_lower)
        raise SecurityError.new("Access to private/local network address #{host.inspect} is prohibited.")
      end

      begin
        resolved_addrs = Socket::Addrinfo.resolve(host_lower, nil, type: Socket::Type::STREAM)
        resolved_addrs.each do |addr|
          ip_str = addr.ip_address.address
          if BLOCKED_HOSTNAMES.includes?(ip_str) || blocked_ip?(ip_str)
            raise SecurityError.new("Access to private/local network address #{host.inspect} (#{ip_str}) is prohibited.")
          end
        end
      rescue ex : SecurityError
        raise ex
      rescue Socket::Addrinfo::Error
        # DNS resolution failure will be handled by the connection attempt
      end
    end

    private def blocked_ip?(clean_ip : String) : Bool
      ip_candidate = clean_ip.starts_with?("::ffff:") ? clean_ip.sub("::ffff:", "") : clean_ip
      if ip_candidate.includes?(':')
        blocked_ipv6?(ip_candidate)
      else
        blocked_ipv4?(ip_candidate)
      end
    end

    private def blocked_ipv6?(ip : String) : Bool
      lower = ip.downcase
      return true if lower == "::1" || lower == "::"
      lower.starts_with?("fe8") || lower.starts_with?("fe9") ||
        lower.starts_with?("fea") || lower.starts_with?("feb") ||
        lower.starts_with?("fc") || lower.starts_with?("fd")
    end

    private def blocked_ipv4?(ip : String) : Bool
      parts = ip.split('.').compact_map(&.to_u32?)
      return false unless parts.size == 4

      p0, p1 = parts[0], parts[1]
      p0 == 127 || p0 == 10 || (p0 == 172 && (16..31).includes?(p1)) ||
        (p0 == 192 && p1 == 168) || (p0 == 169 && p1 == 254) || p0 == 0
    end
  end
end
