module Crinit
  # Recursively mirrors a template directory tree into the target project path.
  class TreeMirrorer
    getter template_dir : Path
    getter config : Config
    getter engine : TokenEngine

    BINARY_EXTENSIONS = {
      ".png", ".jpg", ".jpeg", ".gif", ".ico", ".webp",
      ".pdf", ".zip", ".tar", ".gz", ".xz", ".sqlite3", ".db",
    }

    def initialize(@template_dir : Path, @config : Config, @engine : TokenEngine)
    end

    def render : Nil
      manifest = TemplateManifest.load(template_dir)
      fallback_sources = collect_fallback_sources(manifest)
      files_to_render = collect_entries(fallback_sources)

      check_preflight_conflicts!(files_to_render, manifest)
      render_all_files(files_to_render)
      resolve_remote_assets(manifest)
    end

    private def check_preflight_conflicts!(
      files_to_render : Array({Path, Path}),
      manifest : TemplateManifest?,
    ) : Nil
      conflicting = files_to_render.map { |_, target| target }.select { |target_file| File.exists?(target_file) }

      if manifest
        manifest.remote_assets.each do |asset|
          target_rel = engine.render_path(Path.new(asset.target))
          target_path = PathGuard.ensure_within!(
            config.expanded_dir,
            config.expanded_dir.join(target_rel),
            "remote asset target #{asset.target.inspect}"
          )
          conflicting << target_path if File.exists?(target_path)
        end
      end

      if conflicting.present? && !config.force? && !config.skip_existing?
        raise FilesConflictError.new(conflicting.uniq.map(&.to_s))
      end
    end

    private def render_all_files(files : Array({Path, Path})) : Nil
      files.each do |src, target|
        render_single_file(src, target)
      end
    end

    private def render_single_file(src : Path, target : Path) : Nil
      is_overwrite = File.exists?(target)
      return if is_overwrite && config.skip_existing?

      Dir.mkdir_p(target.dirname)

      if binary_file?(src)
        File.copy(src, target)
      else
        raw_content = File.read(src)
        rendered_content = engine.render_content(raw_content)
        File.write(target, rendered_content)
      end

      apply_file_permissions(src, target)
      log_file_action(target, is_overwrite)
    end

    private def apply_file_permissions(src : Path, target : Path) : Nil
      {% unless flag?(:windows) %}
        src_info = File.info(src)
        File.chmod(target, src_info.permissions)
      {% end %}
    end

    private def log_file_action(target : Path, is_overwrite : Bool) : Nil
      return if config.silent?

      action = is_overwrite ? "overwrite".colorize(:light_green) : "create".colorize(:light_green)
      prefix = is_overwrite ? " " : "    "
      puts "#{prefix}#{action}  #{target}"
    end

    private def resolve_remote_assets(manifest : TemplateManifest?) : Nil
      return unless manifest && manifest.remote_assets.present?

      fetcher = AssetFetcher.new(config, template_dir, engine)
      fetcher.resolve_all(manifest.remote_assets)
    end

    private def collect_fallback_sources(manifest : TemplateManifest?) : Set(Path)
      sources = Set(Path).new
      return sources unless manifest

      manifest.remote_assets.each do |asset|
        if fb = asset.fallback
          fb_path = PathGuard.ensure_within!(
            template_dir,
            template_dir.join(fb),
            "fallback asset #{fb.inspect}"
          )
          sources << fb_path
        end
      end
      sources
    end

    # Returns array of {source_file_path, destination_file_path}
    private def collect_entries(fallback_sources : Set(Path) = Set(Path).new) : Array({Path, Path})
      entries = [] of {Path, Path}
      collect_recursively(template_dir, Path.new(""), entries, fallback_sources)
      entries
    end

    private def collect_recursively(
      current_dir : Path,
      relative_dir : Path,
      entries : Array({Path, Path}),
      fallback_sources : Set(Path),
    ) : Nil
      Dir.each_child(current_dir.to_s) do |child|
        next if ignored_root_entry?(relative_dir, child)

        process_child_entry(current_dir.join(child), relative_dir.join(child), entries, fallback_sources)
      end
    end

    private def ignored_root_entry?(relative_dir : Path, child : String) : Bool
      return false unless relative_dir.parts.empty?

      case child
      when "template.yml", "template.yaml",
           ".template.yml", ".template.yaml",
           ".crinit.yml", ".crinit.yaml",
           ".crinit", ".template",
           "template_assets", ".git", "lib", "bin", ".shards", "shard.lock"
        true
      else
        false
      end
    end

    private def process_child_entry(
      src_child : Path,
      rel_child : Path,
      entries : Array({Path, Path}),
      fallback_sources : Set(Path),
    ) : Nil
      return if fallback_sources.includes?(src_child)

      # Defend against malicious symlink traversal escaping template directory
      if File.symlink?(src_child)
        real_target = Path.new(File.realpath(src_child.to_s))
        PathGuard.ensure_within!(template_dir, real_target, "template symlink #{src_child}")
      end

      if Dir.exists?(src_child) && !File.symlink?(src_child)
        collect_recursively(src_child, rel_child, entries, fallback_sources)
      elsif File.exists?(src_child)
        rendered_rel = engine.render_path(rel_child)
        dest_child = PathGuard.ensure_within!(
          config.expanded_dir,
          config.expanded_dir.join(rendered_rel),
          "mirrored file #{rendered_rel}"
        )
        entries << {src_child, dest_child}
      end
    end

    # Determines whether a file contains binary content based on extension or content probe.
    private def binary_file?(path : Path) : Bool
      ext = path.extension.downcase
      return true if BINARY_EXTENSIONS.includes?(ext)

      File.open(path.to_s) do |file|
        buffer = Bytes.new(8192)
        bytes_read = file.read(buffer)
        buffer[0, bytes_read].any?(&.zero?)
      end
    rescue IO::Error
      false
    end
  end
end
