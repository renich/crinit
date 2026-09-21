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

      verify_path_traversal!(expanded_base, expanded_target, base, target, label)
      verify_symlink_traversal!(expanded_base, expanded_target, base, label)

      expanded_target
    end

    private def self.path_within?(base_str : String, target_str : String) : Bool
      return target_str.starts_with?("/") if base_str == "/"
      target_str == base_str || target_str.starts_with?("#{base_str}#{Path::SEPARATORS.first}")
    end

    private def self.verify_path_traversal!(
      expanded_base : Path,
      expanded_target : Path,
      base : Path,
      target : Path,
      label : String,
    ) : Nil
      unless path_within?(expanded_base.to_s, expanded_target.to_s)
        raise SecurityError.new(
          "Path traversal detected in #{label}: #{target} escapes base directory #{base}"
        )
      end
    end

    private def self.verify_symlink_traversal!(
      expanded_base : Path,
      expanded_target : Path,
      base : Path,
      label : String,
    ) : Nil
      real_base_str = File.exists?(expanded_base) ? File.realpath(expanded_base.to_s) : expanded_base.to_s

      curr : Path? = expanded_target
      while curr && curr != expanded_base && curr.to_s != "/"
        if File.exists?(curr) || File.symlink?(curr)
          real_curr_str = resolve_existing_realpath(curr)
          unless path_within?(real_base_str, real_curr_str)
            raise SecurityError.new(
              "Symlink traversal detected in #{label}: #{curr} points outside base directory #{base}"
            )
          end
          break
        end

        parent = curr.parent
        break if parent == curr
        curr = parent
      end
    end

    private def self.resolve_existing_realpath(curr : Path) : String
      File.realpath(curr.to_s)
    rescue File::NotFoundError
      return curr.to_s unless File.symlink?(curr)
      target_link = Path.new(File.readlink(curr.to_s))
      target_link.absolute? ? target_link.expand.normalize.to_s : curr.parent.join(target_link).expand.normalize.to_s
    end
  end
end
