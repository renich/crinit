require "./spec_helper"
require "http/server"

describe Crinit::AssetFetcher do
  it "resolves asset from local cache (Tier 1)" do
    with_temp_dir("crinit_tier1_cache") do |cache_dir|
      with_temp_dir("crinit_tier1_dest") do |dest_dir|
        with_temp_dir("crinit_tier1_tpl") do |tpl_dir|
          cache = Crinit::CacheStore.new(cache_dir)
          cached_content = "/* Cached CSS */"
          sha = Crinit::CacheStore.digest(cached_content)
          cache.store(sha, cached_content)

          config = Crinit::Config.new(
            name: "web_app",
            dir: dest_dir.to_s,
            silent: true,
            cache_dir: cache_dir
          )
          engine = Crinit::TokenEngine.from_config(config)
          fetcher = Crinit::AssetFetcher.new(config, tpl_dir, engine, cache)

          asset = Crinit::RemoteAsset.new(
            target: "public/app.css",
            url: "https://example.com/unreachable/app.css",
            sha256: sha
          )

          fetcher.resolve_asset(asset)

          dest_file = dest_dir.join("public", "app.css")
          File.exists?(dest_file).should be_true
          File.read(dest_file).should eq(cached_content)
        end
      end
    end
  end

  it "downloads remote asset and populates cache (Tier 2)" do
    server = HTTP::Server.new do |context|
      context.response.content_type = "text/plain"
      context.response.print "Remote Content Payload"
    end
    address = server.bind_tcp("127.0.0.1", 0)
    spawn { server.listen }
    Fiber.yield

    begin
      with_temp_dir("crinit_tier2_cache") do |cache_dir|
        with_temp_dir("crinit_tier2_dest") do |dest_dir|
          with_temp_dir("crinit_tier2_tpl") do |tpl_dir|
            cache = Crinit::CacheStore.new(cache_dir)
            content = "Remote Content Payload"
            sha = Crinit::CacheStore.digest(content)

            config = Crinit::Config.new(
              name: "web_app",
              dir: dest_dir.to_s,
              silent: true,
              cache_dir: cache_dir
            )
            engine = Crinit::TokenEngine.from_config(config)
            fetcher = Crinit::AssetFetcher.new(config, tpl_dir, engine, cache)

            url = "http://127.0.0.1:#{address.port}/asset.txt"
            asset = Crinit::RemoteAsset.new(
              target: "assets/asset.txt",
              url: url,
              sha256: sha
            )

            fetcher.resolve_asset(asset)

            dest_file = dest_dir.join("assets", "asset.txt")
            File.exists?(dest_file).should be_true
            File.read(dest_file).should eq(content)

            cache.has?(sha).should be_true
          end
        end
      end
    ensure
      server.close
    end
  end

  it "raises SecurityError on SHA-256 integrity mismatch" do
    server = HTTP::Server.new do |context|
      context.response.print "Tampered Content"
    end
    address = server.bind_tcp("127.0.0.1", 0)
    spawn { server.listen }
    Fiber.yield

    begin
      with_temp_dir("crinit_sec_cache") do |cache_dir|
        with_temp_dir("crinit_sec_dest") do |dest_dir|
          with_temp_dir("crinit_sec_tpl") do |tpl_dir|
            cache = Crinit::CacheStore.new(cache_dir)
            config = Crinit::Config.new(
              name: "web_app",
              dir: dest_dir.to_s,
              silent: true,
              cache_dir: cache_dir
            )
            engine = Crinit::TokenEngine.from_config(config)
            fetcher = Crinit::AssetFetcher.new(config, tpl_dir, engine, cache)

            url = "http://127.0.0.1:#{address.port}/bad.txt"
            asset = Crinit::RemoteAsset.new(
              target: "bad.txt",
              url: url,
              sha256: "0000000000000000000000000000000000000000000000000000000000000000"
            )

            expect_raises(Crinit::SecurityError, /Integrity verification failed/) do
              fetcher.resolve_asset(asset)
            end
          end
        end
      end
    ensure
      server.close
    end
  end

  it "falls back to bundled template asset when --offline (Tier 3)" do
    with_temp_dir("crinit_tier3_cache") do |cache_dir|
      with_temp_dir("crinit_tier3_dest") do |dest_dir|
        with_temp_dir("crinit_tier3_tpl") do |tpl_dir|
          fallback_file = tpl_dir.join("fallback", "offline.js")
          Dir.mkdir_p(fallback_file.dirname)
          File.write(fallback_file, "console.log('bundled fallback');")

          cache = Crinit::CacheStore.new(cache_dir)
          config = Crinit::Config.new(
            name: "web_app",
            dir: dest_dir.to_s,
            silent: true,
            offline: true,
            cache_dir: cache_dir
          )
          engine = Crinit::TokenEngine.from_config(config)
          fetcher = Crinit::AssetFetcher.new(config, tpl_dir, engine, cache)

          asset = Crinit::RemoteAsset.new(
            target: "public/app.js",
            url: "https://example.com/network/app.js",
            fallback: "fallback/offline.js"
          )

          fetcher.resolve_asset(asset)

          dest_file = dest_dir.join("public", "app.js")
          File.exists?(dest_file).should be_true
          File.read(dest_file).should eq("console.log('bundled fallback');")
        end
      end
    end
  end

  it "creates .todo stub when both network and fallback fail (Tier 4)" do
    with_temp_dir("crinit_tier4_cache") do |cache_dir|
      with_temp_dir("crinit_tier4_dest") do |dest_dir|
        with_temp_dir("crinit_tier4_tpl") do |tpl_dir|
          cache = Crinit::CacheStore.new(cache_dir)
          config = Crinit::Config.new(
            name: "web_app",
            dir: dest_dir.to_s,
            silent: true,
            offline: true,
            cache_dir: cache_dir
          )
          engine = Crinit::TokenEngine.from_config(config)
          fetcher = Crinit::AssetFetcher.new(config, tpl_dir, engine, cache)

          asset = Crinit::RemoteAsset.new(
            target: "fonts/inter.woff2",
            url: "https://example.com/inter.woff2"
          )

          fetcher.resolve_asset(asset)

          stub_file = dest_dir.join("fonts", "inter.woff2.todo")
          File.exists?(stub_file).should be_true
          File.read(stub_file).should contain("Asset could not be automatically fetched")
        end
      end
    end
  end

  it "interpolates tokens in asset target path" do
    with_temp_dir("crinit_interp_cache") do |cache_dir|
      with_temp_dir("crinit_interp_dest") do |dest_dir|
        with_temp_dir("crinit_interp_tpl") do |tpl_dir|
          fallback_file = tpl_dir.join("fallback.css")
          File.write(fallback_file, "body {}")

          cache = Crinit::CacheStore.new(cache_dir)
          config = Crinit::Config.new(
            name: "cool_service",
            dir: dest_dir.to_s,
            silent: true,
            offline: true,
            cache_dir: cache_dir
          )
          engine = Crinit::TokenEngine.from_config(config)
          fetcher = Crinit::AssetFetcher.new(config, tpl_dir, engine, cache)

          asset = Crinit::RemoteAsset.new(
            target: "public/{{name}}.css",
            url: "https://example.com/cool.css",
            fallback: "fallback.css"
          )

          fetcher.resolve_asset(asset)

          dest_file = dest_dir.join("public", "cool_service.css")
          File.exists?(dest_file).should be_true
        end
      end
    end
  end
end
