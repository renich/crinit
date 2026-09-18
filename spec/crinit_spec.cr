# spec/crinit_spec.cr
# Verifies [FUNC-001] and [TECH-001]: CLI option parsing & execution.

require "./spec_helper"

describe Crinit::CLI do
  it "validates valid project names" do
    Crinit::CLI.validate_name("my_project").should be_nil
    Crinit::CLI.validate_name("telemetry-collector").should be_nil
    Crinit::CLI.validate_name("simple").should be_nil
  end

  it "validates template skeleton type" do
    Crinit::CLI.validate_skeleton_type("app").should be_nil
    Crinit::CLI.validate_skeleton_type("kemal-web").should be_nil
    expect_raises(Crinit::InvalidNameError, /Invalid template type/) do
      Crinit::CLI.validate_skeleton_type("../bad/type")
    end
  end

  it "rejects invalid project names" do
    expect_raises(Crinit::InvalidNameError, /must not be empty/) do
      Crinit::CLI.validate_name("")
    end

    expect_raises(Crinit::InvalidNameError, /all lower cased/) do
      Crinit::CLI.validate_name("MyProject")
    end

    expect_raises(Crinit::InvalidNameError, /start with a letter/) do
      Crinit::CLI.validate_name("123app")
    end

    expect_raises(Crinit::InvalidNameError, /consecutive dashes/) do
      Crinit::CLI.validate_name("my--app")
    end

    expect_raises(Crinit::InvalidNameError, /consecutive underscores/) do
      Crinit::CLI.validate_name("my__app")
    end
  end

  it "rejects mutually exclusive --force and --skip-existing" do
    with_temp_dir("crinit_mutex_test") do |dir|
      expect_raises(Crinit::Error, /Cannot use --force and --skip-existing together/) do
        Crinit::CLI.parse_args(["app", dir.to_s, "--force", "--skip-existing"])
      end
    end
  end

  it "initializes an embedded app template project" do
    with_temp_dir("crinit_app_test") do |dir|
      target_dir = dir.join("demo_app")
      Crinit::CLI.run(["app", target_dir.to_s, "--silent", "--no-git"])

      File.exists?(target_dir.join("shard.yml")).should be_true
      File.exists?(target_dir.join("src", "demo_app.cr")).should be_true
      File.exists?(target_dir.join("spec", "spec_helper.cr")).should be_true
      File.exists?(target_dir.join(".editorconfig")).should be_true
      File.exists?(target_dir.join("LICENSE")).should be_true

      shard_content = File.read(target_dir.join("shard.yml"))
      shard_content.should start_with("---\n")
      shard_content.should end_with("...\n")
      shard_content.should contain("name: demo_app")
      shard_content.should contain("main: src/demo_app.cr")
    end
  end

  it "initializes an embedded lib template project" do
    with_temp_dir("crinit_lib_test") do |dir|
      target_dir = dir.join("demo_lib")
      Crinit::CLI.run(["lib", target_dir.to_s, "--silent", "--no-git"])

      File.exists?(target_dir.join("shard.yml")).should be_true
      File.exists?(target_dir.join("src", "demo_lib.cr")).should be_true
      File.exists?(target_dir.join("spec", "spec_helper.cr")).should be_true

      shard_content = File.read(target_dir.join("shard.yml"))
      shard_content.should start_with("---\n")
      shard_content.should end_with("...\n")
      shard_content.should contain("name: demo_lib")
      shard_content.should_not contain("targets:")
    end
  end

  it "initializes a custom template with --template <path> <target_dir>" do
    with_temp_dir("crinit_custom_tpl") do |tpl_dir|
      with_temp_dir("crinit_custom_dest") do |dest_dir|
        File.write(tpl_dir.join("shard.yml"), "---\nname: {{name}}\n...\n")
        Dir.mkdir_p(tpl_dir.join("src"))
        File.write(tpl_dir.join("src", "main.cr"), "puts \"{{module_name}}\"\n")

        target_dir = dest_dir.join("my_service")
        Crinit::CLI.run(["--template", tpl_dir.to_s, target_dir.to_s, "--silent", "--no-git"])

        File.exists?(target_dir.join("shard.yml")).should be_true
        File.read(target_dir.join("shard.yml")).should contain("name: my_service")
        File.read(target_dir.join("src", "main.cr")).should contain("puts \"MyService\"")
      end
    end
  end
end
