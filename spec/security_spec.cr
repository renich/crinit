# spec/security_spec.cr
# Verifies security hardening, path traversal protection, and SSRF defenses.

require "./spec_helper"

describe Crinit::PathGuard do
  it "allows paths inside the base directory" do
    base = Path.new("/tmp/my_project").expand
    target = base.join("src", "main.cr")

    resolved = Crinit::PathGuard.ensure_within!(base, target)
    resolved.should eq(target.expand.normalize)
  end

  it "allows exactly the base directory" do
    base = Path.new("/tmp/my_project").expand
    resolved = Crinit::PathGuard.ensure_within!(base, base)
    resolved.should eq(base.expand.normalize)
  end

  it "raises SecurityError on parent directory traversal (..)" do
    base = Path.new("/tmp/my_project").expand
    target = base.join("..", "..", "etc", "passwd")

    expect_raises(Crinit::SecurityError, /Path traversal detected/) do
      Crinit::PathGuard.ensure_within!(base, target)
    end
  end

  it "raises SecurityError on prefix confusion (/tmp/my_project vs /tmp/my_project_evil)" do
    base = Path.new("/tmp/my_project").expand
    target = Path.new("/tmp/my_project_evil/file.cr").expand

    expect_raises(Crinit::SecurityError, /Path traversal detected/) do
      Crinit::PathGuard.ensure_within!(base, target)
    end
  end
end

describe Crinit::CacheStore do
  it "validates 64-character hexadecimal SHA-256 digests" do
    valid_sha = "fbc9a63fc9fc9f72d12fd7fc9806e11fa9f77ae4f9cad146b27003a1119ba3db"
    Crinit::CacheStore.valid_sha256?(valid_sha).should be_true
  end

  it "rejects invalid or traversing SHA-256 strings" do
    with_temp_dir("crinit_cache_sec_test") do |dir|
      cache = Crinit::CacheStore.new(dir)

      expect_raises(Crinit::SecurityError, /Invalid SHA-256 digest format/) do
        cache.cache_file("../../../etc/shadow")
      end

      expect_raises(Crinit::SecurityError, /Invalid SHA-256 digest format/) do
        cache.store("not_a_sha256", "payload")
      end

      cache.has?("../../../etc/passwd").should be_false
      cache.get("../../../etc/passwd").should be_nil
    end
  end
end

describe "TreeMirrorer & AssetFetcher Security Hardening" do
  it "raises SecurityError when template symlink points outside template directory" do
    with_temp_dir("crinit_symlink_attack_src") do |template_dir|
      with_temp_dir("crinit_symlink_attack_dest") do |dest_dir|
        Dir.mkdir_p(template_dir.join("src"))
        # Create symlink pointing outside template_dir
        outside_file = File.tempfile("crinit_outside", ".txt") { |temp_file| temp_file.print("sensitive") }
        File.symlink(outside_file.path, template_dir.join("src", "evil_link.cr").to_s)

        engine = Crinit::TokenEngine.new({"name" => "victim"})
        config = Crinit::Config.new(name: "victim", dir: dest_dir.to_s, silent: true)

        mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
        expect_raises(Crinit::SecurityError, /template symlink/) do
          mirrorer.render
        end
      ensure
        outside_file.try(&.delete) rescue nil
      end
    end
  end

  it "raises SecurityError when remote asset target attempts path traversal" do
    with_temp_dir("crinit_asset_traversal_src") do |template_dir|
      with_temp_dir("crinit_asset_traversal_dest") do |dest_dir|
        manifest_yaml = <<-YAML
          ---
          name: evil-template
          remote_assets:
            - target: ../../.bashrc
              url: https://example.com/asset.js
          ...
          YAML
        File.write(template_dir.join("template.yml"), manifest_yaml)

        engine = Crinit::TokenEngine.new({"name" => "victim"})
        config = Crinit::Config.new(name: "victim", dir: dest_dir.to_s, silent: true)

        mirrorer = Crinit::TreeMirrorer.new(template_dir, config, engine)
        expect_raises(Crinit::SecurityError, /remote asset target/) do
          mirrorer.render
        end
      end
    end
  end

  it "raises SecurityError when remote asset URL targets cloud metadata endpoint" do
    with_temp_dir("crinit_ssrf_test") do |dest_dir|
      config = Crinit::Config.new(name: "victim", dir: dest_dir.to_s, silent: true)
      engine = Crinit::TokenEngine.new({"name" => "victim"})
      fetcher = Crinit::AssetFetcher.new(config, dest_dir, engine)

      asset = Crinit::RemoteAsset.new(
        target: "metadata.json",
        url: "http://169.254.169.254/latest/meta-data/"
      )

      expect_raises(Crinit::SecurityError, /Access to internal\/metadata address/) do
        fetcher.resolve_asset(asset)
      end
    end
  end
end
