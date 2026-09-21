module Crinit
  class Config
    property skeleton_type : String
    property name : String
    property dir : String
    property author : String
    property email : String
    property github_name : String
    property custom_template_path : String?
    property? force : Bool
    property? skip_existing : Bool
    property? silent : Bool
    property? no_git : Bool
    property? offline : Bool
    property? refresh_assets : Bool
    property? refresh : Bool
    property branch : String?
    property subpath : String?
    property cache_dir : Path?

    def initialize(
      @skeleton_type : String = "app",
      @name : String = "",
      @dir : String = "",
      @author : String = "your-name-here",
      @email : String = "your-email-here",
      @github_name : String = "your-github-user",
      @custom_template_path : String? = nil,
      @force : Bool = false,
      @skip_existing : Bool = false,
      @silent : Bool = false,
      @no_git : Bool = false,
      @offline : Bool = false,
      @refresh_assets : Bool = false,
      @refresh : Bool = false,
      @branch : String? = nil,
      @subpath : String? = nil,
      @cache_dir : Path? = nil,
    )
    end

    def expanded_dir : Path
      Path.new(dir).expand(home: true)
    end

    def github_repo : String
      "#{github_name}/#{expanded_dir.basename}"
    end
  end
end
