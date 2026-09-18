# spec/tree_mirrorer_spec.cr
# Verifies [FUNC-003], [FUNC-005], [FUNC-006] and [TECH-003], [TECH-005]:
# Tree mirroring, conflict detection, binary passthrough, and permissions.

require "./spec_helper"

private def with_mirror_dirs(& : Path, Path ->)
  with_temp_dir("crinit_mirror_src") do |template_dir|
    with_temp_dir("crinit_mirror_dst") do |dest_dir|
      yield template_dir, dest_dir
    end
  end
end

describe Crinit::TreeMirrorer do
  it "mirrors nested directories, interpolates filenames, and renders content [FUNC-003]" do
    with_mirror_dirs do |template_dir, dest_dir|
      Dir.mkdir_p(template_dir.join("src", "{{name}}"))
      Dir.mkdir_p(template_dir.join("config", "database"))

      File.write(template_dir.join("src", "{{name}}", "init.cr"), "module {{module_name}}::Init\nend\n")
      File.write(template_dir.join("config", "database", "connection.cr"), "# Database config for {{name}}\n")

      engine = Crinit::TokenEngine.new({"name" => "my_service", "module_name" => "MyService"})
      config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s)

      mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
      mirrorer.render

      File.exists?(dest_dir.join("src", "my_service", "init.cr")).should be_true
      File.read(dest_dir.join("src", "my_service", "init.cr")).should eq("module MyService::Init\nend\n")

      File.exists?(dest_dir.join("config", "database", "connection.cr")).should be_true
      File.read(dest_dir.join("config", "database", "connection.cr")).should eq("# Database config for my_service\n")
    end
  end

  it "raises FilesConflictError when destination files exist without force/skip" do
    with_mirror_dirs do |template_dir, dest_dir|
      File.write(template_dir.join("README.md"), "# Template\n")
      File.write(dest_dir.join("README.md"), "# Existing\n")

      engine = Crinit::TokenEngine.new({"name" => "my_service"})
      config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s, force: false, skip_existing: false)

      mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
      expect_raises(Crinit::FilesConflictError, /would be overwritten/) do
        mirrorer.render
      end
      File.read(dest_dir.join("README.md")).should eq("# Existing\n")
    end
  end

  it "overwrites existing files when force is true" do
    with_mirror_dirs do |template_dir, dest_dir|
      File.write(template_dir.join("README.md"), "# New Content\n")
      File.write(dest_dir.join("README.md"), "# Old Content\n")

      engine = Crinit::TokenEngine.new({"name" => "my_service"})
      config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s, force: true)

      mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
      mirrorer.render

      File.read(dest_dir.join("README.md")).should eq("# New Content\n")
    end
  end

  it "preserves binary files without corruption [FUNC-005]" do
    with_mirror_dirs do |template_dir, dest_dir|
      binary_bytes = Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0xFF, 0xFE]
      File.write(template_dir.join("image.png"), binary_bytes)

      engine = Crinit::TokenEngine.new({"name" => "my_service"})
      config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s)

      mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
      mirrorer.render

      File.read(dest_dir.join("image.png")).to_slice.should eq(binary_bytes)
    end
  end

  {% unless flag?(:windows) %}
    it "preserves executable permissions on POSIX systems [FUNC-006]" do
      with_mirror_dirs do |template_dir, dest_dir|
        Dir.mkdir_p(template_dir.join("scripts"))
        script_file = template_dir.join("scripts", "run.bash")
        File.write(script_file, "#!/usr/bin/bash\necho ok\n")
        File.chmod(script_file, 0o755)

        engine = Crinit::TokenEngine.new({"name" => "my_service"})
        config = Crinit::Config.new(name: "my_service", dir: dest_dir.to_s)

        mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
        mirrorer.render

        dest_script = dest_dir.join("scripts", "run.bash")
        (File.info(dest_script).permissions.value & 0o111).should_not eq(0)
      end
    end
  {% end %}

  it "processes remote assets from template.yml and excludes fallback sources from direct mirror" do
    with_mirror_dirs do |template_dir, dest_dir|
      Dir.mkdir_p(template_dir.join("src"))
      Dir.mkdir_p(template_dir.join("fallback"))

      File.write(template_dir.join("src", "app.cr"), "puts 123")
      File.write(template_dir.join("fallback", "pico.css"), "/* pico fallback */")

      manifest_yaml = <<-YAML
        ---
        name: kemal-app
        remote_assets:
          - target: public/css/pico.css
            url: https://example.com/unreachable/pico.css
            fallback: fallback/pico.css
        ...
        YAML
      File.write(template_dir.join("template.yml"), manifest_yaml)

      engine = Crinit::TokenEngine.new({"name" => "kemal_test"})
      config = Crinit::Config.new(name: "kemal_test", dir: dest_dir.to_s, offline: true, silent: true)

      mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
      mirrorer.render

      # 1. Standard files mirrored
      File.exists?(dest_dir.join("src", "app.cr")).should be_true

      # 2. template.yml not copied to destination
      File.exists?(dest_dir.join("template.yml")).should be_false

      # 3. Raw fallback source directory not copied to destination root
      File.exists?(dest_dir.join("fallback", "pico.css")).should be_false

      # 4. Target created from fallback
      dest_target = dest_dir.join("public", "css", "pico.css")
      File.exists?(dest_target).should be_true
      File.read(dest_target).should eq("/* pico fallback */")
    end
  end

  it "detects conflicts on remote asset targets during pre-flight check" do
    with_mirror_dirs do |template_dir, dest_dir|
      Dir.mkdir_p(template_dir.join("fallback"))
      File.write(template_dir.join("fallback", "license.txt"), "GPLv3")

      manifest_yaml = <<-YAML
        ---
        name: gpl-app
        remote_assets:
          - target: LICENSE
            url: https://example.com/unreachable/license.txt
            fallback: fallback/license.txt
        ...
        YAML
      File.write(template_dir.join("template.yml"), manifest_yaml)

      File.write(dest_dir.join("LICENSE"), "Existing Proprietary License")

      engine = Crinit::TokenEngine.new({"name" => "gpl_app"})
      config = Crinit::Config.new(name: "gpl_app", dir: dest_dir.to_s, offline: true, silent: true)

      mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
      expect_raises(Crinit::FilesConflictError) do
        mirrorer.render
      end
    end
  end

  it "excludes template.yaml and dot-prefixed manifests from destination" do
    with_mirror_dirs do |template_dir, dest_dir|
      Dir.mkdir_p(template_dir.join("src"))
      File.write(template_dir.join("src", "main.cr"), "puts 1")
      File.write(template_dir.join("template.yaml"), "---\nname: test\n...\n")
      File.write(template_dir.join(".template.yaml"), "---\nname: dot-test\n...\n")

      engine = Crinit::TokenEngine.new({"name" => "test_yaml"})
      config = Crinit::Config.new(name: "test_yaml", dir: dest_dir.to_s, silent: true)

      mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
      mirrorer.render

      File.exists?(dest_dir.join("src", "main.cr")).should be_true
      File.exists?(dest_dir.join("template.yaml")).should be_false
      File.exists?(dest_dir.join(".template.yaml")).should be_false
    end
  end
end
