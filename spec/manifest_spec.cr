require "./spec_helper"

describe Crinit::TemplateManifest do
  it "parses template.yml with remote assets" do
    with_temp_dir("crinit_manifest_test") do |template_dir|
      yaml_content = <<-YAML
        ---
        name: kemal-starter
        description: Full-stack Kemal web starter
        version: 1.0.0
        author: Test Author
        remote_assets:
          - target: LICENSE
            url: https://www.gnu.org/licenses/gpl-3.0.txt
            sha256: 3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986
            fallback: assets/licenses/gpl-3.0.txt
          - target: public/js/datastar.js
            url: https://example.com/datastar.js
            executable: true
        ...
        YAML
      File.write(template_dir.join("template.yml"), yaml_content)

      manifest = Crinit::TemplateManifest.load(template_dir)
      manifest.should_not be_nil
      next unless manifest

      manifest.name.should eq("kemal-starter")
      manifest.description.should eq("Full-stack Kemal web starter")
      manifest.version.should eq("1.0.0")
      manifest.author.should eq("Test Author")
      manifest.remote_assets.size.should eq(2)

      asset1 = manifest.remote_assets[0]
      asset1.target.should eq("LICENSE")
      asset1.url.should eq("https://www.gnu.org/licenses/gpl-3.0.txt")
      asset1.sha256.should eq("3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986")
      asset1.fallback.should eq("assets/licenses/gpl-3.0.txt")
      asset1.executable?.should be_false

      asset2 = manifest.remote_assets[1]
      asset2.target.should eq("public/js/datastar.js")
      asset2.executable?.should be_true
    end
  end

  it "parses template.yaml when template.yml is absent" do
    with_temp_dir("crinit_manifest_yaml_test") do |template_dir|
      yaml_content = <<-YAML
        ---
        name: yaml-starter
        version: 2.0.0
        ...
        YAML
      File.write(template_dir.join("template.yaml"), yaml_content)

      manifest = Crinit::TemplateManifest.load(template_dir)
      manifest.should_not be_nil
      next unless manifest

      manifest.name.should eq("yaml-starter")
      manifest.version.should eq("2.0.0")
    end
  end

  it "prefers template.yml over template.yaml when both exist" do
    with_temp_dir("crinit_manifest_both_test") do |template_dir|
      File.write(template_dir.join("template.yml"), "---\nname: yml-primary\n...\n")
      File.write(template_dir.join("template.yaml"), "---\nname: yaml-secondary\n...\n")

      manifest = Crinit::TemplateManifest.load(template_dir)
      manifest.should_not be_nil
      next unless manifest

      manifest.name.should eq("yml-primary")
    end
  end

  it "returns nil when no template manifest exists" do
    with_temp_dir("crinit_manifest_nil_test") do |dir|
      Crinit::TemplateManifest.load(dir).should be_nil
    end
  end

  it "raises Error on malformed YAML" do
    with_temp_dir("crinit_manifest_bad_test") do |template_dir|
      File.write(template_dir.join("template.yml"), "invalid: [unclosed yaml")
      expect_raises(Crinit::Error, /Failed to parse/) do
        Crinit::TemplateManifest.load(template_dir)
      end
    end
  end
end
