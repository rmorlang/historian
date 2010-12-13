require 'spec_helper'
require 'fileutils'
require 'shellwords'

describe Historian::Git do
  def run_git(*args)
    Dir.chdir repo_directory
    %x(git #{args.collect { |a| Shellwords.escape a }.join " "})
  end

  def tags
    run_git "tag"
  end

  def commit_message_for_tag(tag)
    run_git "show", tag
  end

  def repo_directory
    File.expand_path("../../../tmp/repo", __FILE__)
  end

  def create_test_repo
    FileUtils.rm_rf repo_directory
    FileUtils.mkdir_p repo_directory
    run_git "init", repo_directory
    test_file = File.join repo_directory, "test"
    File.open( test_file, "w") { |f| f.puts "foo" }
    run_git "add", test_file
    run_git "commit", "-m", "test commit"
  end

  before do
    create_test_repo
  end

  subject { @git }
  describe "#bundle_history_file" do

  end

  describe "#tag_release" do
    before do
      @history = StringIO.new(fixture :courageous_camel_history)
      @history.extend Historian::HistoryFile
      @git = Historian::Git.new(repo_directory, @history)
    end

    it "commits the history file if the changelog isn't empty"
    it "commits the history file if it has unstaged changes"

    it "creates a new tag for the latest version" do
      tag = "v" + @history.current_version
      tags.should_not include(tag)
      subject.tag_release
      tags.should include(tag)
    end

    it "annotates the tag with a short message including the version" do
      subject.tag_release
      commit_message_for_tag("v12.0.0").should match(/tagged v12.0.0 "Courageous Camel"/)
    end

    it "annotates the tag with the changelog" do
      subject.tag_release
      commit_message_for_tag("v12.0.0").should include(fixture :courageous_camel_release_log)
    end
  end
end
