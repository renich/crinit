module Crinit
  # Generates built-in standard skeletons (identical to upstream crystal init).
  class EmbeddedViews
    getter config : Config

    def initialize(@config : Config)
    end

    def render : Nil
      views = [
        {".gitignore", gitignore_content},
        {".editorconfig", editorconfig_content},
        {"LICENSE", license_content},
        {"README.md", readme_content},
        {"shard.yml", shard_content},
        {"src/#{config.name}.cr", src_content},
        {"spec/spec_helper.cr", spec_helper_content},
        {"spec/#{config.name}_spec.cr", spec_example_content},
      ]

      # Conflict detection
      existing = views.map { |rel, _| config.expanded_dir.join(rel) }.select { |path| File.exists?(path) }
      if existing.present? && !config.force? && !config.skip_existing?
        raise FilesConflictError.new(existing.map(&.to_s))
      end

      views.each do |rel_path, content|
        target = config.expanded_dir.join(rel_path)
        if File.exists?(target)
          next if config.skip_existing?
          puts " #{"overwrite".colorize(:light_green)}  #{target}" unless config.silent?
        else
          puts "    #{"create".colorize(:light_green)}  #{target}" unless config.silent?
        end

        Dir.mkdir_p(target.dirname)
        File.write(target, content)
      end
    end

    private def module_name : String
      TokenEngine.module_name(config.name)
    end

    private def gitignore_content : String
      String.build do |io|
        io.puts "/docs/"
        io.puts "/lib/"
        io.puts "/bin/"
        io.puts "/.shards/"
        io.puts "*.dwarf"
        if config.skeleton_type == "lib"
          io.puts ""
          io.puts "# Libraries don't need dependency lock"
          io.puts "# Dependencies will be locked in applications that use them"
          io.puts "/shard.lock"
        end
      end
    end

    private def editorconfig_content : String
      <<-INI
        root = true

        [*.cr]
        charset = utf-8
        end_of_line = lf
        insert_final_newline = true
        indent_style = space
        indent_size = 2
        trim_trailing_whitespace = true

        INI
    end

    private def license_content : String
      <<-LICENSE
        MIT License

        Copyright (c) #{Time.local.year} #{config.author} <#{config.email}>

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.

        LICENSE
    end

    private def readme_content : String
      String.build do |io|
        io.puts "# #{config.name}\n\nTODO: Write a description here\n"
        write_installation_section(io)
        write_usage_section(io)
        io.puts "## Development\n\nTODO: Write development instructions here\n"
        write_contributing_section(io)
        io.puts "## Contributors\n\n- [#{config.author}](https://github.com/#{config.github_name}) - creator and maintainer"
      end
    end

    private def write_installation_section(io : IO) : Nil
      io.puts "## Installation\n"
      if config.skeleton_type == "lib"
        io.puts "1. Add the dependency to your `shard.yml`:\n"
        io.puts "   ```yaml"
        io.puts "   dependencies:"
        io.puts "     #{config.name}:"
        io.puts "       github: #{config.github_repo}"
        io.puts "   ```\n"
        io.puts "2. Run `shards install`\n"
      else
        io.puts "TODO: Write installation instructions here\n"
      end
    end

    private def write_usage_section(io : IO) : Nil
      io.puts "## Usage\n"
      if config.skeleton_type == "lib"
        io.puts "```crystal\nrequire \"#{config.name}\"\n```\n"
      end
      io.puts "TODO: Write usage instructions here\n"
    end

    private def write_contributing_section(io : IO) : Nil
      io.puts "## Contributing\n"
      io.puts "1. Fork it (<https://github.com/#{config.github_repo}/fork>)"
      io.puts "2. Create your feature branch (`git checkout -b my-new-feature`)"
      io.puts "3. Commit your changes (`git commit -am 'Add some feature'`)"
      io.puts "4. Push to the branch (`git push origin my-new-feature`)"
      io.puts "5. Create a new Pull Request\n"
    end

    private def shard_content : String
      String.build do |io|
        io.puts "---"
        io.puts "name: #{config.name}"
        io.puts "version: 0.1.0"
        io.puts ""
        io.puts "authors:"
        io.puts "  - #{config.author} <#{config.email}>"
        io.puts ""
        if config.skeleton_type == "app"
          io.puts "targets:"
          io.puts "  #{config.name}:"
          io.puts "    main: src/#{config.name}.cr"
          io.puts ""
        end
        io.puts "crystal: '>= #{Crystal::VERSION}'"
        io.puts ""
        io.puts "license: MIT"
        io.puts "..."
      end
    end

    private def src_content : String
      <<-CRYSTAL
        # TODO: Write documentation for `#{module_name}`
        module #{module_name}
          VERSION = "0.1.0"

          # TODO: Put your code here
        end

        CRYSTAL
    end

    private def spec_helper_content : String
      <<-CRYSTAL
        require "spec"
        require "../src/#{config.name}"

        CRYSTAL
    end

    private def spec_example_content : String
      <<-CRYSTAL
        require "./spec_helper"

        describe #{module_name} do
          # TODO: Write tests

          it "works" do
            false.should eq(true)
          end
        end

        CRYSTAL
    end
  end
end
