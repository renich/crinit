require "spec"
require "file_utils"
require "../src/crinit"

def with_temp_dir(prefix : String = "crinit_test", & : Path ->)
  dir = Path.new(File.tempname(prefix))
  Dir.mkdir_p(dir)
  begin
    yield dir
  ensure
    FileUtils.rm_rf(dir.to_s) if Dir.exists?(dir)
  end
end
