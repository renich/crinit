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

      is_within = if base_str == "/"
                    target_str.starts_with?("/")
                  else
                    target_str == base_str || target_str.starts_with?("#{base_str}#{Path::SEPARATORS.first}")
                  end

      unless is_within
        raise SecurityError.new(
          "Path traversal detected in #{label}: #{target} escapes base directory #{base}"
        )
      end

      if File.symlink?(expanded_target)
        real_target_str = File.realpath(expanded_target.to_s)
        real_base_str = File.exists?(expanded_base) ? File.realpath(expanded_base.to_s) : base_str

        is_real_within = if real_base_str == "/"
                           real_target_str.starts_with?("/")
                         else
                           real_target_str == real_base_str ||
                             real_target_str.starts_with?("#{real_base_str}#{Path::SEPARATORS.first}")
                         end

        unless is_real_within
          raise SecurityError.new(
            "Symlink traversal detected in #{label}: #{target} points outside base directory #{base}"
          )
        end
      end

      expanded_target
    end
  end
end
