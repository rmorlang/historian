require 'spec_helper'

describe Historian::CLI do
  include GitHelpers

  before do
    create_test_repo
    Dir.chdir repo_directory
  end

  context "on initialization" do
    it "finds the root of the current git repository" do
      subdir = File.join repo_directory, "subdir/subdir"
      FileUtils.mkdir_p subdir
      Dir.chdir subdir
      Dir.pwd.should eql(subdir)
      cli = Historian::CLI.new
      cli.git.repo_directory.should eq(repo_directory)
    end

    it "initializes a GitHookInstaller with the repository directory" do
      Historian::Git.should_receive(:new).with(repo_directory, anything).and_return(@ghi)
      cli = Historian::CLI.new
    end

  end

  describe "#commit-msg" do
    context "when an amendment flag exists" do
      it "does not parse the commit message"
    end

    it "opens and parses the commit message"
  end

  describe "#install" do
    before do
      @git = mock("Historian::Git", :install_hook => nil)
      Historian::Git.stub(:new).and_return(@git)
      @cli = Historian::CLI.new
    end

    subject { @cli }

    it "installs the commit-msg hook" do
      @git.should_receive(:install_hook).with(:commit_msg).at_least(:once)
      subject.install
    end

    it "installs the post-commit hook" do
      @git.should_receive(:install_hook).at_least(:once).with(:post_commit)
      subject.install
    end
  end

  describe "parsing the commit message" do
    context "when message contains historian tokens" do
      it "creates a amendment flag"
      it "updates the history file"
      it "updates the commit message with tokens and suppressed lines removed"
    end

    context "when the message contains a release token" do
      it "creates a release flag"
    end
  end

  describe "#post-commit" do
    context "when an amendment flag exists" do
      it "stages the history file"
      it "commits the staged history file"
      it "deletes the amendment flag"
    end

    context "when a release flag exists" do
      it "tags the release"
      it "deletes the release flag"
    end
  end

end
