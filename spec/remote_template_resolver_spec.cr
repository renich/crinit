# spec/remote_template_resolver_spec.cr
# Verifies [FUNC-009] and [ADR-005]: Remote Template Repositories & Local Cache Pipeline.

require "./spec_helper"

describe Crinit::RemoteTemplateResolver do
  describe ".valid_uri?" do
    it "identifies standard Git HTTPS and HTTP URLs [FUNC-009]" do
      Crinit::RemoteTemplateResolver.valid_uri?("https://github.com/kemalcr/kemal-starter.git").should be_true
      Crinit::RemoteTemplateResolver.valid_uri?("http://git.example.org/project/template.git").should be_true
    end

    it "identifies Git protocol and SSH URLs [FUNC-009]" do
      Crinit::RemoteTemplateResolver.valid_uri?("git@github.com:kemalcr/kemal-starter.git").should be_true
      Crinit::RemoteTemplateResolver.valid_uri?("git://github.com/kemalcr/kemal-starter.git").should be_true
      Crinit::RemoteTemplateResolver.valid_uri?("ssh://git@github.com/kemalcr/kemal-starter.git").should be_true
    end

    it "identifies Shards-compatible forge shorthands [FUNC-009]" do
      Crinit::RemoteTemplateResolver.valid_uri?("github:kemalcr/kemal-starter").should be_true
      Crinit::RemoteTemplateResolver.valid_uri?("gitlab:kemalcr/kemal-starter").should be_true
    end

    it "rejects local skeleton names and paths [FUNC-009]" do
      Crinit::RemoteTemplateResolver.valid_uri?("app").should be_false
      Crinit::RemoteTemplateResolver.valid_uri?("lib").should be_false
      Crinit::RemoteTemplateResolver.valid_uri?("kemal-web").should be_false
      Crinit::RemoteTemplateResolver.valid_uri?("./templates/custom").should be_false
      Crinit::RemoteTemplateResolver.valid_uri?("/usr/share/crystal/templates/app").should be_false
    end
  end

  describe ".parse" do
    it "expands github: forge shorthand into canonical Git clone URL [FUNC-009]" do
      remote = Crinit::RemoteTemplateResolver.parse("github:kemalcr/kemal-starter")
      remote.clone_url.should eq("https://github.com/kemalcr/kemal-starter.git")
      remote.ref.should be_nil
    end

    it "expands gitlab: forge shorthand into canonical Git clone URL [FUNC-009]" do
      remote = Crinit::RemoteTemplateResolver.parse("gitlab:group/project")
      remote.clone_url.should eq("https://gitlab.com/group/project.git")
      remote.ref.should be_nil
    end

    it "extracts branch or tag ref from URI fragment [FUNC-009]" do
      remote = Crinit::RemoteTemplateResolver.parse("github:kemalcr/kemal#v1.2.0")
      remote.clone_url.should eq("https://github.com/kemalcr/kemal.git")
      remote.ref.should eq("v1.2.0")

      https_remote = Crinit::RemoteTemplateResolver.parse("https://github.com/org/repo.git#main")
      https_remote.clone_url.should eq("https://github.com/org/repo.git")
      https_remote.ref.should eq("main")
    end

    it "allows explicit ref to override URI fragment [FUNC-009]" do
      remote = Crinit::RemoteTemplateResolver.parse("github:kemalcr/kemal#v1.0.0", explicit_ref: "feature-branch")
      remote.clone_url.should eq("https://github.com/kemalcr/kemal.git")
      remote.ref.should eq("feature-branch")
    end
  end

  describe ".resolve" do
    it "resolves from local cache in --offline mode if present [FUNC-009]" do
      with_temp_dir("crinit_cache_test") do |cache_root|
        uri = "github:crystal-lang/sample-template"
        parsed = Crinit::RemoteTemplateResolver.parse(uri)
        expected_dir = Crinit::RemoteTemplateResolver.cache_dir_for(parsed, cache_root)
        Dir.mkdir_p(expected_dir)
        File.write(expected_dir.join("shard.yml"), "name: cached_sample\n")

        config = Crinit::Config.new(offline: true)
        config.cache_dir = cache_root

        source = Crinit::RemoteTemplateResolver.resolve(uri, config)
        source.should be_a(Crinit::DirectoryTemplateSource)
        source.as(Crinit::DirectoryTemplateSource).path.should eq(expected_dir)
      end
    end

    it "raises TemplateNotFoundError in --offline mode when template is not in cache [FUNC-009]" do
      with_temp_dir("crinit_empty_cache") do |cache_root|
        uri = "github:crystal-lang/uncached-template"
        config = Crinit::Config.new(offline: true)
        config.cache_dir = cache_root

        expect_raises(Crinit::TemplateNotFoundError, /offline mode and no cached copy found/i) do
          Crinit::RemoteTemplateResolver.resolve(uri, config)
        end
      end
    end

    it "resolves a valid repository subpath via --subpath [FUNC-009]" do
      with_temp_dir("crinit_subpath_test") do |cache_root|
        uri = "github:kemalcr/templates"
        parsed = Crinit::RemoteTemplateResolver.parse(uri)
        expected_repo = Crinit::RemoteTemplateResolver.cache_dir_for(parsed, cache_root)
        subpath_dir = expected_repo.join("starters", "web")
        Dir.mkdir_p(subpath_dir)
        File.write(subpath_dir.join("shard.yml"), "name: web_starter\n")

        config = Crinit::Config.new(offline: true)
        config.cache_dir = cache_root

        source = Crinit::RemoteTemplateResolver.resolve(uri, config, subpath: "starters/web")
        source.should be_a(Crinit::DirectoryTemplateSource)
        source.as(Crinit::DirectoryTemplateSource).path.should eq(subpath_dir)
      end
    end

    it "guards against directory traversal attempts in --subpath [FUNC-009]" do
      with_temp_dir("crinit_traversal_test") do |cache_root|
        uri = "github:kemalcr/templates"
        parsed = Crinit::RemoteTemplateResolver.parse(uri)
        expected_repo = Crinit::RemoteTemplateResolver.cache_dir_for(parsed, cache_root)
        Dir.mkdir_p(expected_repo)

        config = Crinit::Config.new(offline: true)
        config.cache_dir = cache_root

        expect_raises(Crinit::SecurityError, /Path traversal detected/) do
          Crinit::RemoteTemplateResolver.resolve(uri, config, subpath: "../../escape")
        end
      end
    end

    it "raises TemplateNotFoundError when specified subpath does not exist in cached repo [FUNC-009]" do
      with_temp_dir("crinit_missing_subpath") do |cache_root|
        uri = "github:kemalcr/templates"
        parsed = Crinit::RemoteTemplateResolver.parse(uri)
        expected_repo = Crinit::RemoteTemplateResolver.cache_dir_for(parsed, cache_root)
        Dir.mkdir_p(expected_repo)

        config = Crinit::Config.new(offline: true)
        config.cache_dir = cache_root

        expect_raises(Crinit::TemplateNotFoundError, /Subpath 'nonexistent' does not exist/) do
          Crinit::RemoteTemplateResolver.resolve(uri, config, subpath: "nonexistent")
        end
      end
    end

    it "performs end-to-end clone and scaffolding from a real Git repository [FUNC-009]" do
      with_temp_dir("crinit_fake_remote") do |origin_dir|
        # Setup fake origin git repo
        Process.run("git", ["init", origin_dir.to_s], output: Process::Redirect::Close)
        Process.run("git", ["-C", origin_dir.to_s, "config", "user.name", "Test Committer"],
          output: Process::Redirect::Close)
        Process.run("git", ["-C", origin_dir.to_s, "config", "user.email", "committer@example.com"],
          output: Process::Redirect::Close)

        File.write(origin_dir.join("shard.yml"), "---\nname: {{name}}\nversion: 0.1.0\n...\n")
        Dir.mkdir_p(origin_dir.join("src"))
        File.write(origin_dir.join("src", "main.cr"), "puts \"Running {{module_name}} by {{author}}\"\n")

        Process.run("git", ["-C", origin_dir.to_s, "add", "."], output: Process::Redirect::Close)
        Process.run("git", ["-C", origin_dir.to_s, "commit", "-m", "Initial template commit"], output: Process::Redirect::Close)

        with_temp_dir("crinit_e2e_dest") do |dest_root|
          target_dir = dest_root.join("cloned_service")
          Crinit::CLI.run(["file://#{origin_dir}", target_dir.to_s, "--silent", "--no-git"])

          File.exists?(target_dir.join("shard.yml")).should be_true
          File.read(target_dir.join("shard.yml")).should contain("name: cloned_service")
          File.read(target_dir.join("src", "main.cr")).should contain("puts \"Running ClonedService by")
        end
      end
    end
  end
end
