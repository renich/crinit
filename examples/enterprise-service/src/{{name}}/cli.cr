module {{module_name}}
  class CLI
    def self.start(args : Array(String) = ARGV) : Nil
      puts "{{module_name}} v#{VERSION}"
    end
  end
end
