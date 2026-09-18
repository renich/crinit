require "option_parser"

module {{module_name}}
  class CLI
    def self.run(args : Array(String) = ARGV) : Nil
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: {{name}} [options]"
        opts.on("-v", "--version", "Show version") do
          puts "{{name}} #{VERSION}"
          exit 0
        end
        opts.on("-h", "--help", "Show help") do
          puts opts
          exit 0
        end
      end

      parser.parse(args)
      puts "Running {{name}} v#{VERSION}..."
    end
  end
end
