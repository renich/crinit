module Crinit
  # Base error class for all crinit exceptions.
  class Error < Exception
  end

  # Raised when project initialization would overwrite existing files.
  class FilesConflictError < Error
    getter conflicting_files : Array(String)

    def initialize(@conflicting_files : Array(String))
      super("Some files would be overwritten: #{conflicting_files.join(", ")}")
    end
  end

  # Raised when a requested template cannot be discovered.
  class TemplateNotFoundError < Error
  end

  # Raised when an invalid project name is provided.
  class InvalidNameError < Error
  end

  # Raised when cryptographic checksum verification fails.
  class SecurityError < Error
  end

  # Raised when an asset cannot be fetched and no fallback is available.
  class AssetFetchError < Error
  end
end
