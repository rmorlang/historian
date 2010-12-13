require 'spec_helper'

describe Historian::HistoryFile do
  context "with no history" do
    before do
      @io = StringIO.new(fixture :empty)
      @io.extend Historian::HistoryFile
    end
    subject {@io}

    context "when not adding history" do
      it { should have_current_version "0.0.0" }
      it { should have_next_version    "0.0.1" }
    end

    context "when adding a patch to history" do
      before do
        @io.update_history :patch => "bugfix #1"
      end

      it { should have_current_version "0.0.0" }
      it { should have_next_version    "0.0.1" }

      it { should have_history_like   :patch_on_nothing }
      it { should have_changelog_like :patch_on_nothing }
    end
  end

  context "with unreleased history" do
    before do
      @io = StringIO.new(fixture :patch_on_nothing)
      @io.extend Historian::HistoryFile
    end
    subject {@io}

    context "when adding a patch to history" do
      before do
        @io.update_history :patch => "bugfix #2"
      end

      it { should have_current_version "0.0.0" }
      it { should have_next_version    "0.0.1" }

      it { should have_history_like   :second_patch_on_nothing }
      it { should have_changelog_like :second_patch_on_nothing }
    end
  end

  context "with unreleased and a 0.0.2 release" do
    before do
      @io = StringIO.new(fixture :after_0_0_2)
      @io.extend Historian::HistoryFile
    end
    subject {@io}

    it { should have_current_version "0.0.2" }
    it { should have_next_version    "0.0.3" }


    context "when adding a patch to history" do
      before do
        @io.update_history :patch => "bugfix #2"
      end

      it { should have_next_version    "0.0.3" }
      it { should have_history_like   :after_0_0_2_history }
      it { should have_changelog_like :after_0_0_2_changelog }
    end
  end

  describe do
    before do
      @io = StringIO.new(fixture :normal)
      @io.extend Historian::HistoryFile
    end
    subject {@io}

    context "after minor changes and bugfixes" do
      before do
        @io.update_history :patch => "bugfix #2",
                        :minor => "minor #1"
      end

      it { should have_current_version "11.22.33" }
      it { should have_next_version    "11.23.0" }

      it { should have_history_like   :normal_history_after_minor   }
      it { should have_changelog_like :normal_changelog_after_minor }
    end

    context "after major changes, minor changes and bugfixes" do
      before do
        @io.update_history :patch => "bugfix #2",
                        :minor => "minor #1",
                        :major => "major #1"
      end

      it { should have_current_version "11.22.33" }
      it { should have_next_version    "12.0.0" }

      it { should have_history_like   :normal_history_after_major   }
      it { should have_changelog_like :normal_changelog_after_major }
    end
  end

  context "when releasing a major change" do
    before do
      Time.stub_chain :now, :strftime => "2010/12/12"
      @io = StringIO.new(fixture :normal)
      @io.extend Historian::HistoryFile
    end
    subject { @io }

    context "with release name 'Courageous Camel'" do
      before do
        @io.update_history :major => "major #1",
                        :release => "Courageous Camel"
      end
      it { should have_current_version "12.0.0" }
      it { should have_next_version    "12.0.1" }
      it { should have_history_like     :courageous_camel_history   }
      it { should have_changelog_like   :empty                      }
      it { should have_release_log_like :courageous_camel_release_log }
      it "returns the release name with #release_name" do
        subject.current_release_name.should eq("Courageous Camel")
      end
    end

    context "with no release name" do
      before do
        @io.update_history :major => "major #1",
                        :release => true
      end

      it { should have_release_log_like :anonymous_release_log }
    end
  end

  context "when parsing a history file with a release and no unreleased changelog" do
    before do
      @io = StringIO.new(fixture :courageous_camel_history)
      @io.extend Historian::HistoryFile
    end
    subject { @io }

    it { should have_current_version "12.0.0" }
    it "returns the release name with #release_name" do
      subject.current_release_name.should eq("Courageous Camel")
    end

  end


end
