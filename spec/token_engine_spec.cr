# spec/token_engine_spec.cr
# Verifies [FUNC-004] and [TECH-004]: Macro-safe token substitution & module derivation.

require "./spec_helper"

describe Crinit::TokenEngine do
  describe ".module_name" do
    it "converts snake_case to PascalCase" do
      Crinit::TokenEngine.module_name("telemetry_daemon").should eq("TelemetryDaemon")
    end

    it "converts kebab-case to nested modules" do
      Crinit::TokenEngine.module_name("telemetry-daemon").should eq("Telemetry::Daemon")
    end

    it "handles mixed snake_case and kebab-case" do
      Crinit::TokenEngine.module_name("fast_math-vector_calc").should eq("FastMath::VectorCalc")
    end

    it "handles single-word identifiers" do
      Crinit::TokenEngine.module_name("crinit").should eq("Crinit")
    end
  end

  describe "#render_content" do
    dictionary = {
      "name"            => "telemetry_collector",
      "module_name"     => "TelemetryCollector",
      "author"          => "Rénich Bon Ćirić",
      "email"           => "renich@evalinux.com",
      "year"            => "2026",
      "crystal_version" => "1.21.0",
    }
    engine = Crinit::TokenEngine.new(dictionary)

    it "substitutes known dictionary tokens" do
      template = "module {{module_name}}\n  VERSION = \"0.1.0\"\n  # Author: {{author}} <{{email}}>\nend"
      expected = "module TelemetryCollector\n  VERSION = \"0.1.0\"\n  # Author: Rénich Bon Ćirić <renich@evalinux.com>\nend"
      engine.render_content(template).should eq(expected)
    end

    it "preserves native Crystal macro calls without corruption [FUNC-004]" do
      template = "{% if flag?(:linux) %}\n  {{ @type.name }}\n{% end %}\nLog.info { \"{{name}}\" }"
      expected = "{% if flag?(:linux) %}\n  {{ @type.name }}\n{% end %}\nLog.info { \"telemetry_collector\" }"
      engine.render_content(template).should eq(expected)
    end

    it "unescapes explicitly escaped macro delimiters" do
      template = "Defines a macro: \\{{ my_macro_call \\}}"
      expected = "Defines a macro: {{ my_macro_call }}"
      engine.render_content(template).should eq(expected)
    end

    it "unescapes escaped tokens without substituting dictionary values" do
      template = "Literal token: \\{{name\\}}"
      expected = "Literal token: {{name}}"
      engine.render_content(template).should eq(expected)
    end
  end

  describe "#render_path" do
    dictionary = {"name" => "my_service"}
    engine = Crinit::TokenEngine.new(dictionary)

    it "interpolates tokens within filenames and directories" do
      raw_path = Path.new("src", "{{name}}", "{{name}}.cr")
      expected = Path.new("src", "my_service", "my_service.cr")
      engine.render_path(raw_path).should eq(expected)
    end

    it "leaves paths without tokens untouched" do
      raw_path = Path.new("config", "database", "connection.cr")
      engine.render_path(raw_path).should eq(raw_path)
    end
  end
end
