module Crinit
  abstract class TemplateSource
  end

  class DirectoryTemplateSource < TemplateSource
    getter path : Path

    def initialize(@path : Path)
    end
  end

  class EmbeddedTemplateSource < TemplateSource
    getter name : String

    def initialize(@name : String)
    end
  end

  # Resolves template locations across CLI arguments, environment variables, OS paths, and remote repositories.
  module TemplateResolver
    def self.resolve(
      type : String,
      explicit_path : String? = nil,
      config : Config = Config.new,
      subpath : String? = nil,
    ) : TemplateSource
      effective_subpath = subpath || config.subpath

      # 1. Explicit CLI Path or Remote URI
      if explicit_path
        if RemoteTemplateResolver.valid_uri?(explicit_path)
          return RemoteTemplateResolver.resolve(explicit_path, config, effective_subpath)
        end

        exp_path = Path.new(explicit_path).expand
        if effective_subpath && !effective_subpath.empty?
          candidate = exp_path.join(effective_subpath)
          PathGuard.ensure_within!(exp_path, candidate, "template subpath #{effective_subpath.inspect}")
          if Dir.exists?(candidate)
            return DirectoryTemplateSource.new(candidate)
          else
            raise TemplateNotFoundError.new(
              "Subpath '#{effective_subpath}' does not exist in template directory #{exp_path}."
            )
          end
        end

        if Dir.exists?(exp_path)
          return DirectoryTemplateSource.new(exp_path)
        else
          raise TemplateNotFoundError.new("Explicit template path does not exist: #{explicit_path}")
        end
      end

      # 2. Remote URI Type
      if RemoteTemplateResolver.valid_uri?(type)
        return RemoteTemplateResolver.resolve(type, config, effective_subpath)
      end

      # 2. Search Paths in Priority Order
      candidate_paths(type).each do |candidate|
        if Dir.exists?(candidate)
          return DirectoryTemplateSource.new(candidate)
        end
      end

      # 3. Fallback to Embedded Standard Views
      if type.in?("app", "lib")
        return EmbeddedTemplateSource.new(type)
      end

      raise TemplateNotFoundError.new(
        "No template found for '#{type}'. Verified workspace, user XDG/AppSupport, and system paths."
      )
    end

    private def self.candidate_paths(type : String) : Array(Path)
      raw_paths = [] of Path

      # Priority 2: CRYSTAL_TEMPLATE_PATH environment variable
      if env_path = ENV["CRYSTAL_TEMPLATE_PATH"]?.presence
        env_path.split(Process::PATH_DELIMITER, remove_empty: true).each do |base|
          raw_paths << Path.new(base, type).expand
        end
      end

      # Priority 3: Local Workspace Override
      raw_paths << Path.new(".crystal", "templates", type).expand

      # Priority 4: OS-Native User Template Directory
      raw_paths.concat(user_template_paths(type))

      # Priority 5: OS-Native System Template Directory
      raw_paths.concat(system_template_paths(type))

      candidates = [] of Path
      raw_paths.uniq.each do |candidate_path|
        base = candidate_path.parent
        PathGuard.ensure_within!(base, candidate_path, "template candidate #{type.inspect}")
        candidates << candidate_path
      rescue SecurityError
        next
      end
      candidates
    end

    private def self.user_template_paths(type : String) : Array(Path)
      paths = [] of Path

      {% if flag?(:windows) %}
        if local_appdata = ENV["LOCALAPPDATA"]?.presence
          paths << Path.new(local_appdata, "crystal", "templates", type)
        end
        if user_profile = ENV["USERPROFILE"]?.presence
          paths << Path.new(user_profile, ".crystal", "templates", type)
        end
      {% elsif flag?(:darwin) %}
        if home = ENV["HOME"]?.presence
          paths << Path.new(home, "Library", "Application Support", "crystal", "templates", type)
          paths << Path.new(home, ".local", "share", "crystal", "templates", type)
        end
      {% else %}
        if xdg_data = ENV["XDG_DATA_HOME"]?.presence
          paths << Path.new(xdg_data, "crystal", "templates", type)
        elsif home = ENV["HOME"]?.presence
          paths << Path.new(home, ".local", "share", "crystal", "templates", type)
        end
      {% end %}

      paths
    end

    private def self.system_template_paths(type : String) : Array(Path)
      paths = [] of Path

      if exec_path = Process.executable_path
        paths << Path.new(exec_path).parent.join("..", "share", "crystal", "templates", type).expand
      end

      {% if flag?(:windows) %}
        if prog_files = ENV["ProgramFiles"]?.presence
          paths << Path.new(prog_files, "Crystal", "templates", type)
        end
      {% elsif flag?(:darwin) %}
        paths << Path.new("/opt/homebrew/share/crystal/templates", type)
        paths << Path.new("/usr/local/share/crystal/templates", type)
      {% else %}
        paths << Path.new("/usr/share/crystal/templates", type)
        paths << Path.new("/usr/local/share/crystal/templates", type)
      {% end %}

      paths
    end
  end
end
