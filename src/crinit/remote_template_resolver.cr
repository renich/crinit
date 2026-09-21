require "openssl/digest"
require "file_utils"

module Crinit
  # Represents a parsed and normalized remote repository reference.
  record RemoteURI, original : String, clone_url : String, ref : String?, slug : String

  # Resolves remote Git repositories and forge templates with local caching.
  module RemoteTemplateResolver
    def self.valid_uri?(string : String) : Bool
      return false if string.blank?
      return true if string.starts_with?("github:") || string.starts_with?("gitlab:")
      return true if string.starts_with?("https://") || string.starts_with?("http://")
      return true if string.starts_with?("git://") || string.starts_with?("ssh://") || string.starts_with?("git@")
      return true if string.starts_with?("file://")

      false
    end

    def self.parse(uri : String, explicit_ref : String? = nil) : RemoteURI
      case
      when uri.starts_with?("github:")
        parse_shorthand("https://github.com", uri.sub("github:", ""), uri, explicit_ref)
      when uri.starts_with?("gitlab:")
        parse_shorthand("https://gitlab.com", uri.sub("gitlab:", ""), uri, explicit_ref)
      else
        parse_direct_url(uri, explicit_ref)
      end
    end

    def self.cache_dir_for(parsed : RemoteURI, custom_base : Path? = nil) : Path
      base_dir = custom_base ? resolve_custom_base(custom_base) : default_cache_dir
      sanitized_slug = parsed.slug.gsub(/[^a-zA-Z0-9_-]/, "_")

      digest = OpenSSL::Digest.new("SHA256")
      digest.update("#{parsed.clone_url}##{parsed.ref}")
      hash = digest.hexfinal[0, 16]

      base_dir.join("#{sanitized_slug}_#{hash}")
    end

    def self.resolve(
      uri : String,
      config : Config = Config.new,
      subpath : String? = nil,
    ) : DirectoryTemplateSource
      parsed = parse(uri, config.branch)
      repo_dir = cache_dir_for(parsed, config.cache_dir)
      effective_subpath = subpath || config.subpath

      if config.offline?
        ensure_offline_cached!(uri, repo_dir)
      else
        ensure_online_fetched!(parsed, repo_dir, config.refresh?)
      end

      target_dir = resolve_subpath_target(repo_dir, effective_subpath, parsed.clone_url)
      DirectoryTemplateSource.new(target_dir)
    end

    private def self.parse_shorthand(
      base_host : String,
      body : String,
      original : String,
      explicit_ref : String?,
    ) : RemoteURI
      repo_part, fragment = body.includes?('#') ? body.split('#', 2) : {body, nil}
      repo_part = repo_part.sub(/\.git\z/, "")
      parts = repo_part.split('/', 2)

      owner = parts[0]? || "unknown"
      repo_name = parts[1]? || "template"
      clone_url = "#{base_host}/#{owner}/#{repo_name}.git"
      ref = explicit_ref || fragment
      slug = "#{owner}_#{repo_name}"

      RemoteURI.new(original, clone_url, ref, slug)
    end

    private def self.parse_direct_url(uri : String, explicit_ref : String?) : RemoteURI
      clean_url, fragment = uri.includes?('#') ? uri.split('#', 2) : {uri, nil}
      ref = explicit_ref || fragment

      slug_raw = clean_url.split('/').last?.try(&.sub(/\.git\z/, "")) || "remote_repo"
      slug = slug_raw.gsub(/[^a-zA-Z0-9_-]/, "_")

      RemoteURI.new(uri, clean_url, ref, slug)
    end

    private def self.resolve_custom_base(custom_base : Path) : Path
      custom_base.basename == "remotes" ? custom_base : custom_base.join("remotes")
    end

    private def self.ensure_offline_cached!(uri : String, repo_dir : Path) : Nil
      unless Dir.exists?(repo_dir)
        raise TemplateNotFoundError.new(
          "Cannot fetch remote template #{uri.inspect}: offline mode and no cached copy found in #{repo_dir}."
        )
      end
    end

    private def self.ensure_online_fetched!(parsed : RemoteURI, repo_dir : Path, refresh : Bool) : Nil
      if !Dir.exists?(repo_dir) || refresh
        clone_or_refresh(parsed, repo_dir)
      end
    end

    private def self.clone_or_refresh(parsed : RemoteURI, repo_dir : Path) : Nil
      FileUtils.rm_rf(repo_dir.to_s) if Dir.exists?(repo_dir)
      Dir.mkdir_p(repo_dir.parent)

      args = ["clone", "--depth", "1"]
      if ref = parsed.ref
        args << "--branch" << ref
      end
      args << parsed.clone_url << repo_dir.to_s

      success = Git.git_command(args)
      unless success
        FileUtils.rm_rf(repo_dir.to_s) if Dir.exists?(repo_dir)
        raise Error.new("Failed to clone remote template from #{parsed.clone_url} (ref: #{parsed.ref || "default"}).")
      end
    end

    private def self.resolve_subpath_target(
      repo_dir : Path,
      subpath : String?,
      clone_url : String,
    ) : Path
      return repo_dir if subpath.nil? || subpath.empty?

      candidate = repo_dir.join(subpath)
      PathGuard.ensure_within!(repo_dir, candidate, "remote template subpath #{subpath.inspect}")

      unless Dir.exists?(candidate)
        raise TemplateNotFoundError.new(
          "Subpath '#{subpath}' does not exist in remote template repository #{clone_url}."
        )
      end

      candidate
    end

    private def self.default_cache_dir : Path
      CacheStore.default_base_cache_dir.join("remotes")
    end
  end
end
