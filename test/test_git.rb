require File.expand_path('../helper', __FILE__)
require 'fileutils'
require 'mini_portile'
require 'erb'
require 'tmpdir'

class TestGit < TestCase
  class << self
    attr_accessor :assets_path
    attr_accessor :tar_path
    attr_accessor :recipe
    attr_accessor :git_dir
    attr_accessor :commit_sha

    def startup
      @assets_path = File.expand_path("../assets", __FILE__)
      @tar_path = File.expand_path("../../tmp/test-digest-1.0.0.tar.gz", __FILE__)

      # remove any previous test files
      FileUtils.rm_rf("tmp")

      create_tar(@tar_path, @assets_path)
      start_webrick(File.dirname(@tar_path))
    end

    def shutdown
      stop_webrick
      # leave test files for inspection
    end
  end

  def setup
    # remove any download files
    FileUtils.rm_rf("ports/archives")
    @recipe = MiniPortile.new("test-digest", "1.0.0")

    @git_dir = Dir.mktmpdir

    Dir.chdir(@git_dir) do
      system('git init && touch file && git add . && git commit -m "initial"')
      @commit_sha = `git rev-parse HEAD`.strip
    end
  end

  def cleanup
    FileUtils.rm_rf(@git_dir)
  end

  def test_with_valid_git_commit_sha
    @recipe.files << {
      :url => "http://localhost:#{self.class.webrick.config[:Port]}/#{ERB::Util.url_encode(File.basename(self.class.tar_path))}",
      :git => {
        :commit_sha => @commit_sha,
        :dir => @git_dir
      }
    }
    @recipe.download
  end

  def test_with_wrong_git_commit_sha
    @recipe.files << {
      :url => "http://localhost:#{self.class.webrick.config[:Port]}/#{ERB::Util.url_encode(File.basename(self.class.tar_path))}",
      :git => {
        :commit_sha => "a_mocked_commit_sha",
        :dir => @git_dir
      }
    }
    exception = assert_raise(RuntimeError){ @recipe.download }
    assert_equal("Invalid commit sha, expected: a_mocked_commit_sha, got: #{@commit_sha}", exception.message)
  end
end
