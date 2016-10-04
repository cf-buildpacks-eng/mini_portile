require File.expand_path('../helper', __FILE__)
require 'fileutils'
require 'mini_portile'
require 'erb'
require 'tmpdir'

class TestGit < TestCase
  class << self
    attr_accessor :recipe
    attr_accessor :home_dir
    attr_accessor :working_dir
  end

  def setup
    @working_dir = Dir.mktmpdir
    @home_dir = Dir.pwd

    Dir.chdir(@working_dir)

    @recipe = MiniPortile.new("dotnet-core", "v1.0.0-preview2.0.1")
  end

  def cleanup
    Dir.chdir(@home_dir)
    FileUtils.rm_rf(@working_dir)
  end

  def test_with_valid_git_commit_sha
    @recipe.files << {
      :url => "https://github.com/dotnet/cli",
      :git => {
        :commit_sha => "635cf40e58ede8a53e8b9555e19a6e1ccd6f9fbe"
      }
    }
    @recipe.download
  end

  def test_with_invalid_git_commit_sha
    @recipe.files << {
      :url => "https://github.com/dotnet/cli",
      :git => {
        :commit_sha => "a_mocked_commit_sha"
      }
    }
    exception = assert_raise(RuntimeError){ @recipe.download }
    assert_equal("Invalid commit sha, expected: a_mocked_commit_sha, got: 635cf40e58ede8a53e8b9555e19a6e1ccd6f9fbe", exception.message)
  end
end
