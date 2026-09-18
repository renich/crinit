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
      files_to_render = collect_entries

      # Step 1: Pre-flight conflict check
      existing = files_to_render.select { |_, target| File.exists?(target) }
      if existing.present? && !config.force? && !config.skip_existing?
        raise FilesConflictError.new(existing.map { |_, target| target.to_s })
      end

      # Step 2: Render directories and files
      files_to_render.each do |src, target|
        is_overwrite = File.exists?(target)
        if is_overwrite && config.skip_existing?
          next
        end

        Dir.mkdir_p(target.dirname)

        if binary_file?(src)
          File.copy(src, target)
        else
          raw_content = File.read(src)
          rendered_content = engine.render_content(raw_content)
          File.write(target, rendered_content)
        end

        # Step 3: Preserve executable permissions on POSIX systems
        {% unless flag?(:windows) %}
          src_info = File.info(src)
          File.chmod(target, src_info.permissions)
        {% end %}

        unless config.silent?
          action = is_overwrite ? "overwrite".colorize(:light_green) : "create".colorize(:light_green)
          prefix = is_overwrite ? " " : "    "
          puts "#{prefix}#{action}  #{target}"
        end
      end
    end

    # Returns array of {source_file_path, destination_file_path}
    private def collect_entries : Array({Path, Path})
      entries = [] of {Path, Path}

      collect_recursively(template_dir, Path.new(""), entries)
      entries
    end

    private def collect_recursively(current_dir : Path, relative_dir : Path, entries : Array({Path, Path})) : Nil
      Dir.each_child(current_dir.to_s) do |child|
        # Ignore metadata, build artifacts, and dependency state in template root
        if relative_dir.parts.empty? && (
             child == "template.yml" || child == "template.yaml" ||
             child == ".git" || child == "lib" || child == "bin" ||
             child == ".shards" || child == "shard.lock"
           )
          next
        end

        src_child = current_dir.join(child)
        rel_child = relative_dir.join(child)

        if Dir.exists?(src_child) && !File.symlink?(src_child)
          collect_recursively(src_child, rel_child, entries)
        elsif File.exists?(src_child)
          rendered_rel = engine.render_path(rel_child)
          dest_child = config.expanded_dir.join(rendered_rel)
          entries << {src_child, dest_child}
        end
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
