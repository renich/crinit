require "yaml"

module Crinit
  # Represents an individual remote asset declaration inside template.yml.
  class RemoteAsset
    include YAML::Serializable

    getter target : String
    getter url : String
    getter sha256 : String?
    getter fallback : String?
    getter? executable : Bool = false

    def initialize(
      @target : String,
      @url : String,
      @sha256 : String? = nil,
      @fallback : String? = nil,
      @executable : Bool = false,
    )
    end
  end

  # Represents the metadata and remote assets manifest for a template.
  class TemplateManifest
    include YAML::Serializable

    getter name : String?
    getter description : String?
    getter version : String?
    getter author : String?

    @[YAML::Field(key: "remote_assets")]
    getter remote_assets : Array(RemoteAsset) = [] of RemoteAsset

    def initialize(
      @name : String? = nil,
      @description : String? = nil,
      @version : String? = nil,
      @author : String? = nil,
      @remote_assets : Array(RemoteAsset) = [] of RemoteAsset,
    )
    end

    # Discovers and parses template manifest from the template root.
    # Supports both .yml and .yaml extensions (template.yml, template.yaml,
    # .template.yml, .template.yaml, .crinit.yml, .crinit.yaml).
    # Returns nil if no manifest file exists.
    def self.load(template_dir : Path) : TemplateManifest?
      candidates = [
        template_dir.join("template.yml"),
        template_dir.join("template.yaml"),
        template_dir.join(".template.yml"),
        template_dir.join(".template.yaml"),
        template_dir.join(".crinit.yml"),
        template_dir.join(".crinit.yaml"),
      ]

      path = candidates.find { |candidate| File.exists?(candidate) }
      return unless path

      begin
        from_yaml(File.read(path))
      rescue ex : YAML::ParseException
        raise Error.new("Failed to parse #{path}: #{ex.message}")
      end
    end
  end
end
