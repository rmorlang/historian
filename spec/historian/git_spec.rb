require 'spec_helper'

describe Historian::Git do
  include GitHelpers

  before do
    create_test_repo
  end

  subject { @git }

  describe "#bundle_history_file" do
    before do
      @history = history_for_repo :courageous_camel_history
      @git = Historian::Git.new(repo_directory, @history)
    end

    subject { @git }

    it "amends the previous commit to include changes to the history file" do
      modified?(@history_file).should be_true
      lambda { subject.bundle_history_file }.should_not change(self, :commits_count)
      modified?(@history_file).should be_false
    end
  end

  describe "#install_hook" do
    before do
      @git = Historian::Git.new(repo_directory, nil)
      @hook = "foo-bar"
      @hook_sym = :foo_bar
      @hook_wrapper = File.join(repo_directory, ".git", "hooks", @hook)
      @hook_script = File.join(repo_directory, ".git", "hooks", @hook + ".d", "historian")
    end

    shared_examples_for "creating the hook sub-script" do
      it "creates the hook script" do
        File.exists?(@hook_script).should be_true
      end

      it "makes the hook script executable" do
        File.stat(@hook_script).should be_executable
      end

      describe "contents" do
        before do
          @contents = File.readlines @hook_script
        end

        it "should be a bash script" do
          @contents.first.start_with?("#!/bin/bash").should be_true
        end

        it "should invoke the hook exactly once" do
          @contents.grep("bundle exec historian #{@hook_sym} $@\n").should have(1).match
        end
      end
    end

    shared_examples_for "creating the hook wrapper" do
      it "creates a directory for hooks scripts" do
        File.directory?(File.dirname @hook_script).should be_true
      end

      it "creates a wrapper script" do
        File.exists?(@hook_wrapper).should be_true
      end

      it "makes the hook script executable" do
        File.stat(@hook_wrapper).should be_executable
      end

      describe "contents" do
        before do
          @contents = File.readlines @hook_wrapper
        end

        it "should be a bash script" do
          @contents.first.start_with?("#!/bin/bash").should be_true
        end

        it "should invoke all the scripts in the hook script directory" do
          invoke = /for S in .*#{@hook}.d/
          @contents.grep(invoke).should have(1).match
        end
      end
    end

    context "with no existing hook" do
      before do
        @result = @git.install_hook(@hook_sym)
      end

      it "returns :created" do
        @result.should eq(:created)
      end

      it_behaves_like "creating the hook wrapper"
      it_behaves_like "creating the hook sub-script"
    end

    context "when the hook is already installed" do
      before do
        @result = @git.install_hook(@hook_sym)
      end

      it "does not modify the hook file" do
        File.should_not_receive(:open).with(@hook_script, /w/)
        @git.install_hook @hook_sym
      end

      it "returns :exists" do
        @git.install_hook(@hook_sym).should eq(:exists)
      end
    end

    context "when another hook is already installed" do
      before do
        @original_contents = "the original script!"
        File.open(@hook_wrapper, "w") { |f| f.write @original_contents }
        @result = @git.install_hook(@hook_sym)
      end

      it "returns :adapted" do
        @result.should eq(:adapted)
      end

      it "copies the original hook file into the hook's script directory" do
        new_location = File.join File.dirname(@hook_script), "original"
        File.read(new_location).should eq(@original_contents)
      end

      it_behaves_like "creating the hook wrapper"
      it_behaves_like "creating the hook sub-script"
    end
  end

  describe "#tag_release" do
    shared_examples_for "a tagged release" do
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

    describe "with a dirty history file" do
      before do
        @history = history_for_repo :courageous_camel_history
        @history.update_history :minor => "some little thing"
        @git = Historian::Git.new(repo_directory, @history)
      end

      subject { @git }

      it "releases the history file if the changelog isn't empty" do
        @history.should_receive :release
        subject.tag_release
      end

      it "commits the history file if it has unstaged changes" do
        subject.should_receive(:commit_history_changes).twice
        subject.tag_release
      end

      it_behaves_like "a tagged release"
    end

    describe "with a clean history file" do
      before do
        @history = history_for_repo :courageous_camel_history
        run_git "add", @history.path
        run_git "commit", "-m", "clean the history"
        @git = Historian::Git.new(repo_directory, @history)
      end

      subject { @git }

      it "does not commit the history file" do
        subject.should_not_receive :commit_history_changes
        subject.tag_release
      end

      it_behaves_like "a tagged release"

    end
  end
end
