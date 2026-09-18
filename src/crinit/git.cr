module Crinit::Git
  class_property executable : String = "git"

  # Executes a Git command with given arguments.
  def self.git_command(args : Array(String), output : Process::Stdio = Process::Redirect::Close) : Bool
    Process.run(executable, args, output: output).success?
  rescue IO::Error
    false
  end

  # Captures standard output from a Git command.
  def self.git_capture(args : Array(String)) : String?
    String.build do |io|
      return unless git_command(args, output: io)
    end
  end

  # Reads a Git configuration key.
  def self.git_config(key : String) : String?
    git_capture(["config", "--get", key]).try(&.strip).presence
  end

  # Initializes a Git repository in the target directory.
  def self.init(dir : String, silent : Bool = false) : Bool
    output = silent ? Process::Redirect::Close : Process::Redirect::Inherit
    git_command(["init", dir], output: output)
  end
end
