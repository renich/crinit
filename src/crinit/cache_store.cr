require "openssl/digest"

module Crinit
  # Manages content-addressed local caching for remote assets based on SHA-256 digests.
  class CacheStore
    getter cache_dir : Path

    def initialize(custom_dir : Path? = nil)
      @cache_dir = custom_dir || default_cache_dir
    end

    def self.from_config(config : Config) : CacheStore
      new(config.cache_dir)
    end

    # Checks whether an asset with the given SHA-256 is present and uncorrupted in the cache.
    def has?(sha256 : String) : Bool
      target = cache_file(sha256)
      return false unless File.exists?(target)

      # Verify integrity of cached file
      computed = compute_file_sha256(target)
      if computed.downcase == sha256.downcase
        true
      else
        # Remove corrupted cache file
        File.delete(target) rescue nil
        false
      end
    end

    # Retrieves the path to the cached asset, or nil if absent or corrupted.
    def get(sha256 : String) : Path?
      has?(sha256) ? cache_file(sha256) : nil
    end

    # Atomically stores content in cache indexed by SHA-256 digest.
    def store(sha256 : String, data : Bytes | String) : Path
      Dir.mkdir_p(cache_dir)
      target = cache_file(sha256)

      # Atomic write using a temp file
      temp_path = cache_dir.join(".tmp_#{sha256}_#{Random::Secure.hex(4)}")
      File.open(temp_path.to_s, "w") do |file|
        case data
        when Bytes
          file.write(data)
        when String
          file.print(data)
        end
      end

      File.rename(temp_path, target)
      target
    end

    def cache_file(sha256 : String) : Path
      cache_dir.join(sha256.downcase)
    end

    # Computes SHA-256 hex digest for binary or string data.
    def self.digest(data : Bytes | String) : String
      digest = OpenSSL::Digest.new("SHA256")
      case data
      when Bytes
        digest.update(data)
      when String
        digest.update(data.to_slice)
      end
      digest.hexfinal
    end

    private def compute_file_sha256(path : Path) : String
      digest = OpenSSL::Digest.new("SHA256")
      File.open(path.to_s) do |file|
        buffer = Bytes.new(16384)
        while (bytes_read = file.read(buffer)) > 0
          digest.update(buffer[0, bytes_read])
        end
      end
      digest.hexfinal
    rescue IO::Error
      ""
    end

    private def default_cache_dir : Path
      {% if flag?(:windows) %}
        base = ENV["LOCALAPPDATA"]? || ENV["TEMP"]? || "."
        Path.new(base).join("crystal", "crinit", "assets")
      {% elsif flag?(:darwin) %}
        Path.home.join("Library", "Caches", "crystal", "crinit", "assets")
      {% else %}
        base = ENV["XDG_CACHE_HOME"]? || Path.home.join(".cache").to_s
        Path.new(base).join("crystal", "crinit", "assets")
      {% end %}
    end
  end
end
