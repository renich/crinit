# spec/template_resolver_spec.cr
# Verifies [FUNC-002] and [TECH-002]: Multi-Platform template discovery.

require "./spec_helper"

describe Crinit::TemplateResolver do
  it "resolves an explicit template directory from a filesystem path" do
    with_temp_dir("crinit_explicit_tpl") do |custom_dir|
      File.write(custom_dir.join("shard.yml"), "name: custom\n")

      resolved = Crinit::TemplateResolver.resolve("ignored", explicit_path: custom_dir.to_s)
      resolved.should be_a(Crinit::DirectoryTemplateSource)
      resolved.as(Crinit::DirectoryTemplateSource).path.should eq(custom_dir.expand.normalize)
    end
  end

  it "resolves from CRYSTAL_TEMPLATE_PATH environment variable" do
    with_temp_dir("crinit_env_tpl_base") do |base_dir|
      service_dir = base_dir.join("service")
      Dir.mkdir_p(service_dir)
      File.write(service_dir.join("shard.yml"), "name: service\n")

      orig_env = ENV["CRYSTAL_TEMPLATE_PATH"]?
      begin
        ENV["CRYSTAL_TEMPLATE_PATH"] = base_dir.to_s
        resolved = Crinit::TemplateResolver.resolve("service")
        resolved.should be_a(Crinit::DirectoryTemplateSource)
        resolved.as(Crinit::DirectoryTemplateSource).path.should eq(service_dir.expand.normalize)
      ensure
        if orig_env
          ENV["CRYSTAL_TEMPLATE_PATH"] = orig_env
        else
          ENV.delete("CRYSTAL_TEMPLATE_PATH")
        end
      end
    end
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

  it "routes remote URIs to remote template resolution [FUNC-009]" do
    with_temp_dir("crinit_remote_resolver_route") do |cache_root|
      uri = "github:kemalcr/kemal-starter"
      parsed = Crinit::RemoteTemplateResolver.parse(uri)
      cached_path = Crinit::RemoteTemplateResolver.cache_dir_for(parsed, cache_root)
      Dir.mkdir_p(cached_path)
      File.write(cached_path.join("shard.yml"), "name: routed_template\n")

      config = Crinit::Config.new(offline: true)
      config.cache_dir = cache_root

      source = Crinit::TemplateResolver.resolve(uri, config: config)
      source.should be_a(Crinit::DirectoryTemplateSource)
      source.as(Crinit::DirectoryTemplateSource).path.should eq(cached_path)
    end
  end
end
