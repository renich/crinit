require "option_parser"
require "colorize"

module Crinit
  # Command-line interface driver and argument parser for crinit.
  class CLI
    def self.run(args : Array(String) = ARGV) : Nil
      config = parse_args(args)
      run_with_config(config)
    rescue ex : FilesConflictError
      STDERR.puts "Cannot initialize Crystal project, the following files would be overwritten:".colorize(:red)
      ex.conflicting_files.each do |path|
        STDERR.puts "   #{"file".colorize(:red)} #{path} #{"already exists".colorize(:red)}"
      end
      STDERR.puts "You can use --force to overwrite those files,"
      STDERR.puts "or --skip-existing to skip existing files and generate the others."
      exit 1
    rescue ex : InvalidNameError | TemplateNotFoundError | Error
      STDERR.puts "Cannot initialize Crystal project: #{ex.message}".colorize(:red)
      exit 1
    end

    def self.run_with_config(config : Config) : Nil
      if File.exists?(config.expanded_dir) && !Dir.exists?(config.expanded_dir)
        raise Error.new("#{config.dir.inspect} exists and is not a directory")
      end

      source = TemplateResolver.resolve(config.skeleton_type, config.custom_template_path)

      case source
      when DirectoryTemplateSource
        engine = TokenEngine.from_config(config)
        TreeMirrorer.new(source.path, config, engine).render
      when EmbeddedTemplateSource
        EmbeddedViews.new(config).render
      end

      unless config.no_git?
        Git.init(config.dir, silent: config.silent?)
      end
    end

    def self.parse_args(args : Array(String)) : Config
      config = Config.new

      parser = OptionParser.new do |opts|
        opts.banner = <<-USAGE
          Usage: crinit TYPE (DIR | NAME DIR) [OPTIONS]

          Initializes a Crystal project folder as a git repository using built-in
          skeletons or filesystem templates.

          TYPE is one of:
              app                      Creates an application skeleton (built-in)
              lib                      Creates a library skeleton (built-in)
              <custom>                 Discovers template from local, user, or system paths

          DIR  - directory where project will be generated
          NAME - name of project to be generated (default: basename of DIR)
          USAGE

        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit 0
        end

        opts.on("-v", "--version", "Show version") do
          puts "crinit #{VERSION}"
          exit 0
        end

        opts.on("-f", "--force", "Force overwrite of existing files") do
          config.force = true
        end

        opts.on("-s", "--skip-existing", "Skip existing files without erroring") do
          config.skip_existing = true
        end

        opts.on("-t PATH", "--template=PATH", "Use an explicit filesystem template path") do |path|
          config.custom_template_path = path
        end

        opts.on("--offline", "Do not download remote assets; use cache or bundled fallbacks") do
          config.offline = true
        end

        opts.on("--refresh-assets", "Bypass local cache and re-download remote assets") do
          config.refresh_assets = true
        end

        opts.on("--no-git", "Do not initialize a Git repository") do
          config.no_git = true
        end

        opts.on("--silent", "Suppress stdout logging") do
          config.silent = true
        end

        opts.unknown_args do |remaining|
          if remaining.empty?
            puts opts
            exit 1
          end

          config.skeleton_type = remaining.shift

          if remaining.empty?
            STDERR.puts "Error: Missing target directory argument.".colorize(:red)
            puts opts
            exit 1
          end

          dir_arg = remaining.shift
          if remaining.empty?
            config.dir = dir_arg
            config.name = config.expanded_dir.basename
          else
            config.name = dir_arg
            config.dir = remaining.shift
          end
        end
      end

      parser.parse(args)

      if config.dir.empty?
        STDERR.puts "Error: Target directory must be specified.".colorize(:red)
        exit 1
      end

      if config.force? && config.skip_existing?
        raise Error.new("Cannot use --force and --skip-existing together")
      end

      validate_name(config.name)

      config.author = Git.git_config("user.name") || "your-name-here"
      config.email = Git.git_config("user.email") || "your-email-here"
      config.github_name = Git.git_config("github.user") || "your-github-user"

      config
    end

    def self.validate_name(name : String) : Nil
      case
      when name.blank?
        raise InvalidNameError.new("NAME must not be empty")
      when name.size > 50
        raise InvalidNameError.new("NAME must not be longer than 50 characters")
      when name.each_char.any?(&.uppercase?)
        raise InvalidNameError.new("NAME should be all lower cased")
      when !name[0].ascii_letter?
        raise InvalidNameError.new("NAME must start with a letter")
      when name.includes?("--")
        raise InvalidNameError.new("NAME must not have consecutive dashes")
      when name.includes?("__")
        raise InvalidNameError.new("NAME must not have consecutive underscores")
      when !name.each_char.all? { |char| char.alphanumeric? || char.in?('-', '_') }
        raise InvalidNameError.new("NAME must only contain alphanumerical characters, underscores or dashes")
      end
    end
  end
end
