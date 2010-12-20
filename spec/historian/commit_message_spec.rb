require 'spec_helper'

describe Historian::CommitMessage do
  describe "#parse line" do
    describe "#supressed?" do
      subject { Historian::CommitMessage.parse_line(@line) }

      it "is suppressed if the line contains a supression token" do
        @line = "b#: suppress me"
        subject.should be_suppressed
      end

      it "is not suppressed if the line doesn't have a suppression token" do
        @line = "b: don't suppress me"
        subject.should_not be_suppressed
      end

      it "is not suppressed if the line has no Historian token" do
        @line = "x: not really a token!"
        subject.should_not be_suppressed
      end
    end

    describe "#to_s" do
      subject { Historian::CommitMessage.parse_line(@line).to_s }

      it "returns the input if the string contains no Historian token" do
        @line = "a line without a token"
        subject.should eq(@line)
      end
      it "is strips the Historian token from the string if present" do
        @line = "M: * major!"
        subject.should eq(" * major!")
      end
    end

    describe "#to_messsage_s" do
      subject { Historian::CommitMessage.parse_line(@line).to_message_s }

      it "is nil with no token" do
        @line = "no token"
        subject.should be_nil
      end

      it "strips whitespace from the beginning of the string" do
        @line = "M: major!"
        subject.should eq("major!")
      end

      it "strips non alphanumeric characters from the beginning of the string" do
        @line = "M: * major!"
        subject.should eq("major!")
      end
    end

    describe "#significance" do
      subject { Historian::CommitMessage.parse_line(@line).significance }

      it "is nil with token that doesn't precede an alphanumeric" do
        @line = "b: * ^^ !"
        subject.should be_nil
      end

      it "is nil with no Historian token" do
        @line = "there's no token here"
        subject.should be_nil
      end

      it "is nil if the token doesn't start at the beginning of the line" do
        @line = " b: this isn't a bugfix"
        subject.should be_nil
      end

      it "is :patch with a bugfix token" do
        @line = "b: this is a bugfix"
        subject.should eq(:patch)
      end

      it "is :minor with a minor improvement token" do
        @line = "m: this is a minor improvement"
        subject.should eq(:minor)
      end

      it "is :major with a major improvement token" do
        @line = "M: this is a major improvement"
        subject.should eq(:major)
      end

      it "is :release with a release token" do
        @line = "!: this is a release"
        subject.should eq(:release)
      end
    end
  end
end
