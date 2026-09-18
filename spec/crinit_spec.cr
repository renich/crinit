# spec/crinit_spec.cr
# Verifies [FUNC-001] and [TECH-001]: CLI option parsing & execution.

require "./spec_helper"
require "file_utils"

describe Crinit::CLI do
  around_each do |example|
    temp_dir = File.tempname("crinit_cli_test")
    Dir.mkdir_p(temp_dir)
    begin
      FileUtils.cd(temp_dir) do
        example.run
      end
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  it "validates valid project names" do
    Crinit::CLI.validate_name("my_project")
    Crinit::CLI.validate_name("telemetry-collector")
    Crinit::CLI.validate_name("simple")
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

  it "initializes an embedded app template project" do
    Crinit::CLI.run(["app", "demo_app", "--no-git"])

    File.exists?("demo_app/shard.yml").should be_true
    File.exists?("demo_app/src/demo_app.cr").should be_true
    File.exists?("demo_app/spec/spec_helper.cr").should be_true
    File.exists?("demo_app/.editorconfig").should be_true
    File.exists?("demo_app/LICENSE").should be_true

    shard_content = File.read("demo_app/shard.yml")
    shard_content.should start_with("---\n")
    shard_content.should end_with("...\n")
    shard_content.should contain("name: demo_app")
    shard_content.should contain("main: src/demo_app.cr")
  end

  it "initializes an embedded lib template project" do
    Crinit::CLI.run(["lib", "demo_lib", "--no-git"])

    File.exists?("demo_lib/shard.yml").should be_true
    File.exists?("demo_lib/src/demo_lib.cr").should be_true
    File.exists?("demo_lib/spec/spec_helper.cr").should be_true

    shard_content = File.read("demo_lib/shard.yml")
    shard_content.should start_with("---\n")
    shard_content.should end_with("...\n")
    shard_content.should contain("name: demo_lib")
    shard_content.should_not contain("targets:")
  end
end
