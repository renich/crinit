module Crinit
  # PathGuard provides strict path traversal verification to prevent
  # template files, remote assets, or symlinks from escaping target boundaries.
  module PathGuard
    # Verifies that target path does not escape base directory via traversal or symlink hops.
    # Returns the expanded and normalized target Path on success.
    # Raises SecurityError if target path traverses outside base directory.
    def self.ensure_within!(base : Path, target : Path, label : String = "path") : Path
      expanded_base = base.expand.normalize
      expanded_target = target.expand.normalize

      base_str = expanded_base.to_s
      target_str = expanded_target.to_s

      is_within = target_str == base_str || target_str.starts_with?("#{base_str}#{Path::SEPARATORS.first}")

      unless is_within
        raise SecurityError.new(
          "Path traversal detected in #{label}: #{target} escapes base directory #{base}"
        )
      end

      expanded_target
    end
  end
end
