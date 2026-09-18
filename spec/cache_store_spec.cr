require "./spec_helper"

describe Crinit::CacheStore do
  it "stores and retrieves assets by SHA-256" do
    with_temp_dir("crinit_cache_test") do |cache_dir|
      cache = Crinit::CacheStore.new(cache_dir)
      content = "Hello, Crystal Scaffolding Cache!"
      digest = Crinit::CacheStore.digest(content)

      cache.has?(digest).should be_false
      cache.get(digest).should be_nil

      stored_path = cache.store(digest, content)
      File.exists?(stored_path).should be_true

      cache.has?(digest).should be_true
      cache.get(digest).should eq(stored_path)
      File.read(stored_path).should eq(content)
    end
  end

  it "detects and deletes corrupted cached files" do
    with_temp_dir("crinit_cache_corrupt_test") do |cache_dir|
      cache = Crinit::CacheStore.new(cache_dir)
      content = "Authentic content"
      digest = Crinit::CacheStore.digest(content)

      stored_path = cache.store(digest, content)
      cache.has?(digest).should be_true

      # Corrupt the cached file
      File.write(stored_path, "Tampered content")

      # has? should detect corruption, purge file, and return false
      cache.has?(digest).should be_false
      File.exists?(stored_path).should be_false
    end
  end

  it "computes SHA-256 digests accurately" do
    Crinit::CacheStore.digest("test").should eq("9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08")
  end
end
