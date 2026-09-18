# spec/template_resolver_spec.cr
# Verifies [FUNC-002] and [TECH-002]: Multi-Platform template discovery.

require "./spec_helper"
require "file_utils"

describe Crinit::TemplateResolver do
  around_each do |example|
    temp_dir = File.tempname("crinit_resolver_test")
    Dir.mkdir_p(temp_dir)
    begin
      FileUtils.cd(temp_dir) do
        example.run
      end
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  it "resolves an explicit template directory from a filesystem path" do
    custom_dir = Path.new("custom_template").expand
    Dir.mkdir_p(custom_dir)
    File.write(custom_dir.join("shard.yml"), "name: custom\n")

    resolved = Crinit::TemplateResolver.resolve("ignored", explicit_path: custom_dir.to_s)
    resolved.should be_a(Crinit::DirectoryTemplateSource)
    resolved.as(Crinit::DirectoryTemplateSource).path.should eq(custom_dir)
  end

  it "resolves from workspace local ./.crystal/templates/<TYPE>" do
    local_dir = Path.new(".crystal", "templates", "service").expand
    Dir.mkdir_p(local_dir)
    File.write(local_dir.join("shard.yml"), "name: service\n")

    resolved = Crinit::TemplateResolver.resolve("service")
    resolved.should be_a(Crinit::DirectoryTemplateSource)
    resolved.as(Crinit::DirectoryTemplateSource).path.should eq(local_dir)
  end

  it "falls back to embedded templates for 'app' and 'lib'" do
    app_resolved = Crinit::TemplateResolver.resolve("app")
    app_resolved.should be_a(Crinit::EmbeddedTemplateSource)
    app_resolved.as(Crinit::EmbeddedTemplateSource).name.should eq("app")

    lib_resolved = Crinit::TemplateResolver.resolve("lib")
    lib_resolved.should be_a(Crinit::EmbeddedTemplateSource)
    lib_resolved.as(Crinit::EmbeddedTemplateSource).name.should eq("lib")
  end

  it "raises TemplateNotFoundError when template cannot be resolved" do
    expect_raises(Crinit::TemplateNotFoundError, /No template found/) do
      Crinit::TemplateResolver.resolve("non_existent_skeleton_type")
    end
  end
end
