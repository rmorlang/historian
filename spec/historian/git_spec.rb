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
        subject.should_receive :commit_history_changes
        subject.tag_release
      end

      it_behaves_like "a tagged release"
    end

    describe "with a clean history file" do
      before do
        @history = history_for_repo :courageous_camel_history
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
