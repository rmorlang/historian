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

    it "creates a history file if none exists" do
      ProjectScout.stub :scan => repo_directory
      File.should_receive(:exists?).and_return(false)
      File.stub(:open).and_return(StringIO.new)
      File.should_receive(:open).at_least(:once).with(/History.txt/, "w")
      cli = Historian::CLI.new
    end

    it "initializes a GitHookInstaller with the repository directory" do
      Historian::Git.should_receive(:new).with(repo_directory, anything).and_return(@ghi)
      cli = Historian::CLI.new
    end

  end

  describe "#commit-msg" do
    before do
      @message_file = "/tmp/historian_test_message"
      @cli = Historian::CLI.new
    end

    context "when an amendment flag exists" do
      before do
        @amend_flag = File.join(repo_directory, ".git", "historian-amend")
        File.open(@amend_flag, "w")
      end

      it "does not parse the commit message" do
        File.should_not_receive(:open).with(@message_file)
        @cli.commit_msg @message_file
      end
    end

    context "when message contains no historian tokens" do
      before do
        File.open(@message_file, "w") do |f|
          f.puts "test bugfix"
        end
        @cli.commit_msg @message_file
      end

      after do
        File.unlink @message_file
      end

      it "doesn't create an amend flag" do
        amend_flag = File.join(repo_directory, ".git", "historian-amend")
        File.exists?(amend_flag).should be_false
      end

      it "doesn't update the history file" do
        history_file = File.join repo_directory, "History.txt"
        modified?(history_file).should be_false
      end
    end

    context "when message contains historian tokens" do
      before do
        File.open(@message_file, "w") do |f|
          f.puts "b:test bugfix"
        end
        @cli.commit_msg @message_file
      end

      after do
        File.unlink @message_file
      end

      it "creates an amend flag" do
        amend_flag = File.join(repo_directory, ".git", "historian-amend")
        File.exists?(amend_flag).should be_true
      end

      it "updates the history file" do
        history_file = File.join repo_directory, "History.txt"
        history = File.readlines(history_file)
        history.grep(/test bugfix/).should have(1).match
        modified?(history_file).should be_true
      end

      it "strips the tokens out of the message file" do
        File.read(@message_file).should_not match(/b:/)
      end

      it "updates the commit message with tokens and suppressed lines removed" do
        File.read(@message_file).should eq("test bugfix\n")
      end
    end

    context "when the message contains a release token" do
      before do
        File.open(@message_file, "w") do |f|
          f.puts "!:Addled Adder"
        end
        @cli.commit_msg @message_file
      end

      after do
        File.unlink @message_file
      end

      it "creates a release flag" do
        release_flag = File.join(repo_directory, ".git", "historian-release")
        File.exists?(release_flag).should be_true
      end

      it "creates an amend flag" do
        amend_flag = File.join(repo_directory, ".git", "historian-amend")
        File.exists?(amend_flag).should be_true
      end

      it "strips the tokens out of the message file" do
        File.read(@message_file).should_not match(/!:/)
      end

      it "updates the history file" do
        history_file = File.join repo_directory, "History.txt"
        history = File.readlines(history_file)
        history.grep(/== 0.0.1 Addled Adder/).should have(1).match
        modified?(history_file).should be_true
      end
    end
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


  describe "#post-commit" do
    before do
      @git = mock("Historian::Git",
                  :bundle_history_file => nil,
                  :tag_release => nil)
      Historian::Git.stub(:new).and_return(@git)
      @cli = Historian::CLI.new
    end

    context "when an amendment flag exists" do
      before do
        @amend_flag = File.join(repo_directory, ".git", "historian-amend")
        File.open(@amend_flag, "w")
      end

      it "bundles the history file" do
        @git.should_receive :bundle_history_file
        @cli.post_commit
      end

      it "deletes the amendment flag" do
        @cli.post_commit
        File.exists?(@amend_flag).should_not be_true
      end
    end

    context "when a release flag exists" do
      before do
        @release_flag = File.join(repo_directory, ".git", "historian-release")
        File.open(@release_flag, "w")
      end

      it "tags the release" do
        @git.should_receive :tag_release
        @cli.post_commit
      end

      it "deletes the release flag" do
        @cli.post_commit
        File.exists?(@release_flag).should_not be_true
      end
    end
  end

end
