module Crinit
  # Evaluates and interpolates substitution tokens across file contents and paths.
  class TokenEngine
    getter dictionary : Hash(String, String)

    TOKEN_REGEX   = /\{\{([a-zA-Z0-9_]+)\}\}/
    ESCAPED_OPEN  = "\x00CRINIT_ESC_OPEN\x00"
    ESCAPED_CLOSE = "\x00CRINIT_ESC_CLOSE\x00"

    def initialize(@dictionary : Hash(String, String) = Hash(String, String).new)
    end

    # Builds a standard dictionary from Crinit::Config.
    def self.from_config(config : Config) : self
      dict = {
        "name"            => config.name,
        "module_name"     => module_name(config.name),
        "author"          => config.author,
        "email"           => config.email,
        "github_user"     => config.github_name,
        "github_repo"     => config.github_repo,
        "year"            => Time.local.year.to_s,
        "crystal_version" => Crystal::VERSION,
      }
      new(dict)
    end

    # Converts project identifiers to valid Crystal module names.
    # Hyphens indicate nested namespaces (e.g. foo-bar -> Foo::Bar).
    # Underscores convert to PascalCase within the same namespace (e.g. foo_bar -> FooBar).
    def self.module_name(name : String) : String
      name
        .gsub(/[-_]([^a-z])/i, "\\1")
        .split('-')
        .compact_map do |part|
          part.camelcase if part[0]?.try(&.ascii_letter?)
        end
        .join("::")
    end

    # Renders a string template, substituting recognized tokens while preserving
    # unmapped macro delimiters and unescaping explicit macro escapes.
    def render_content(content : String) : String
      return content unless content.includes?("{{")

      # Pass 1: Protect explicit escape markers
      guarded = content
        .gsub(/\\\{\{/, ESCAPED_OPEN)
        .gsub(/\\\}\}/, ESCAPED_CLOSE)

      # Pass 2: Substitute only known dictionary keys
      substituted = guarded.gsub(TOKEN_REGEX) do |match, regex_match|
        key = regex_match[1]?
        if key && (val = dictionary[key]?)
          val
        else
          match
        end
      end

      # Pass 3: Restore escaped macro tokens to literal {{ and }}
      substituted
        .gsub(ESCAPED_OPEN, "{{")
        .gsub(ESCAPED_CLOSE, "}}")
    end

    # Interpolates tokens within a relative or absolute filesystem Path.
    def render_path(path : Path) : Path
      path_str = path.to_s
      return path unless path_str.includes?("{{")

      Path.new(render_content(path_str))
    end
  end
end
