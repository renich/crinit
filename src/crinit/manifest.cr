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

    # Discovers and parses template.yml or template.yaml from the template root.
    # Returns nil if neither manifest file exists.
    def self.load(template_dir : Path) : TemplateManifest?
      yml_path = template_dir.join("template.yml")
      yaml_path = template_dir.join("template.yaml")

      path = if File.exists?(yml_path)
               yml_path
             elsif File.exists?(yaml_path)
               yaml_path
             end

      return unless path

      begin
        from_yaml(File.read(path))
      rescue ex : YAML::ParseException
        raise Error.new("Failed to parse #{path}: #{ex.message}")
      end
    end
  end
end
