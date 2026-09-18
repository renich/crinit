# spec/tree_mirrorer_spec.cr
# Verifies [FUNC-003], [FUNC-005], [FUNC-006] and [TECH-003], [TECH-005]:
# Tree mirroring, conflict detection, binary passthrough, and permissions.

require "./spec_helper"
require "file_utils"

describe Crinit::TreeMirrorer do
  around_each do |example|
    temp_dir = File.tempname("crinit_mirrorer_test")
    Dir.mkdir_p(temp_dir)
    begin
      FileUtils.cd(temp_dir) do
        example.run
      end
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  it "mirrors nested directories, interpolates filenames, and renders content [FUNC-003]" do
    template_dir = Path.new("template").expand
    Dir.mkdir_p(template_dir.join("src", "{{name}}"))
    Dir.mkdir_p(template_dir.join("config", "database"))

    File.write(template_dir.join("src", "{{name}}", "init.cr"), "module {{module_name}}::Init\nend\n")
    File.write(template_dir.join("config", "database", "connection.cr"), "# Database config for {{name}}\n")

    dest_dir = Path.new("dest").expand
    engine = Crinit::TokenEngine.new({"name" => "my_service", "module_name" => "MyService"})
    config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s)

    mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
    mirrorer.render

    File.exists?(dest_dir.join("src", "my_service", "init.cr")).should be_true
    File.read(dest_dir.join("src", "my_service", "init.cr")).should eq("module MyService::Init\nend\n")

    File.exists?(dest_dir.join("config", "database", "connection.cr")).should be_true
    File.read(dest_dir.join("config", "database", "connection.cr")).should eq("# Database config for my_service\n")
  end

  it "raises FilesConflictError when destination files exist without force/skip" do
    template_dir = Path.new("template").expand
    Dir.mkdir_p(template_dir)
    File.write(template_dir.join("README.md"), "# Template\n")

    dest_dir = Path.new("dest").expand
    Dir.mkdir_p(dest_dir)
    File.write(dest_dir.join("README.md"), "# Existing\n")

    engine = Crinit::TokenEngine.new({"name" => "my_service"})
    config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s, force: false, skip_existing: false)

    mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
    expect_raises(Crinit::FilesConflictError, /would be overwritten/) do
      mirrorer.render
    end
    File.read(dest_dir.join("README.md")).should eq("# Existing\n")
  end

  it "overwrites existing files when force is true" do
    template_dir = Path.new("template").expand
    Dir.mkdir_p(template_dir)
    File.write(template_dir.join("README.md"), "# New Content\n")

    dest_dir = Path.new("dest").expand
    Dir.mkdir_p(dest_dir)
    File.write(dest_dir.join("README.md"), "# Old Content\n")

    engine = Crinit::TokenEngine.new({"name" => "my_service"})
    config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s, force: true)

    mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
    mirrorer.render

    File.read(dest_dir.join("README.md")).should eq("# New Content\n")
  end

  it "preserves binary files without corruption [FUNC-005]" do
    template_dir = Path.new("template").expand
    Dir.mkdir_p(template_dir)

    binary_bytes = Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0xFF, 0xFE]
    File.write(template_dir.join("image.png"), binary_bytes)

    dest_dir = Path.new("dest").expand
    engine = Crinit::TokenEngine.new({"name" => "my_service"})
    config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s)

    mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
    mirrorer.render

    File.read(dest_dir.join("image.png")).to_slice.should eq(binary_bytes)
  end

  {% unless flag?(:windows) %}
    it "preserves executable permissions on POSIX systems [FUNC-006]" do
      template_dir = Path.new("template").expand
      Dir.mkdir_p(template_dir.join("scripts"))
      script_file = template_dir.join("scripts", "run.bash")
      File.write(script_file, "#!/usr/bin/bash\necho ok\n")
      File.chmod(script_file, 0o755)

      dest_dir = Path.new("dest").expand
      engine = Crinit::TokenEngine.new({"name" => "my_service"})
      config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s)

      mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
      mirrorer.render

      dest_script = dest_dir.join("scripts", "run.bash")
      (File.info(dest_script).permissions.value & 0o111).should_not eq(0)
    end
  {% end %}
end
