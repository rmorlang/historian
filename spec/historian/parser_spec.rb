require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

EXAMPLE_HISTORY = <<EOF
This is some freeform data that's not part of a specific version.

== 1.0.0 2009-03-01

Some plain text about the last release.

=== Changed Features
* first change
* second change
 
== 0.9.1 2009-02-01

Some other details about this older release.

More stuff.

=== Changes
* something
* something



== 0.9.0 2009-01-01

Another release
EOF
BEFORE_HISTORY = <<EOF
== In Git

The first stable release announced to the world.

=== New Features
* many new widgets

== 0.1 2009-01-01

Experimental development release. Not for wide distribution.

== New Features
* code was written
EOF
AFTER_HISTORY = <<EOF
== In Git

The first stable release announced to the world.

=== New Features
* many new widgets
* pleasant popping sounds
* enticing aromas

=== Bugfixes
* 1 is no longer equal to 2

== 0.1 2009-01-01

Experimental development release. Not for wide distribution.

== New Features
* code was written
EOF



module Historian
  describe Parser do
    before do
      @config = OpenStruct.new :map => {
        "new" => "New Features",
        "bugfix" => "Bugfixes"
      }
      @data_to_use = EXAMPLE_HISTORY
    end

    subject { Parser.new(StringIO.new(@data_to_use), @config) }

    describe "prepare_to_scan" do
      it "should reset the index to 0" do
        subject.index = 1
        subject.prepare_to_scan
        subject.index.should == 0
      end
    end

    describe "scan_for_release" do
      it "should find the first release by default and position the index to that line" do
        subject.scan_for_release.should match(/^== 1.0.0/)
        subject.index.should == 2
      end

      it "should return an existing release and position the index to that line" do
        subject.scan_for_release("0.9.1").should match(/^== 0.9.1/)
        subject.index.should == 10
      end

      it "should return nil and position the index past the last element if no release found" do
        subject.scan_for_release("not exist").should be_nil
        subject.index.should == subject.data.count
      end
    end

    describe "compare section keys" do
      before do
        @line = "=== New Features\n"
      end

      it "should return nil if no section keys match the current line" do
        subject.compare_section_keys(["nomatch"], :against => @line).should be_nil
      end

      it "should return a matching key if found" do
        subject.compare_section_keys(["nomatch", "new"], :against => @line).should == "new"
      end

      it "should return the key and not its map" do
        subject.compare_section_keys(["nomatch", "New Features"], :against => @line).should == "new"
      end
    end

    describe "status" do
      it "should prepare to scan" do 
        subject.should_receive(:prepare_to_scan)
        subject.status
      end

      it "should scan for the specified header" do
        subject.should_receive(:scan_for_release).with("1.0.0")
        subject.status("1.0.0")
      end

      it "should return the text for the most recent release by default" do        
        lines = subject.status.split("\n")
        lines.should have(7).lines
        lines.first.should == "== 1.0.0 2009-03-01"
        lines.last.should == "* second change"
      end

      it "should return the text for a named release" do
        lines = subject.status("0.9.1").split("\n")
        lines.should have(9).lines
        lines.first.should == "== 0.9.1 2009-02-01"
        lines.last.should == "* something"
      end

      it "should return nil if no release is found" do
        subject.status("2.0").should be_nil
      end
    end

    describe "add" do
      it "should prepaVre to scan" do
        subject.stub! :io => mock("io", :eof? => true, :tell => 0, :seek => true)
        subject.stub! :result => mock("result").as_null_object
        subject.should_receive(:prepare_to_scan)
        subject.add("key" => "value")
      end

      it "should scan for the first release marker" do
        subject.should_receive(:scan_for_release).with(no_args)
        subject.add("key" => "value")
      end

      describe "to a new section" do
        it "should create the section by key" do
          result = subject.add("somekey" => "value")

          result[2].should =~ /^== In Git/
          result[4].should =~ /^=== somekey/
          result[5].should =~ /^\* value/
          result[7].should =~ /^== 1.0.0/
        end

        it "should create the section by key mapping" do
          result = subject.add("new" => "value")
          result[4].should =~ /^=== New Features/
        end
      end

      # this is more of an integration test that covers all of Historian's
      # add functionality.
      it "should both append to existing sections and create new ones" do
        @data_to_use = BEFORE_HISTORY
        result = subject.add(
          "new" => ["pleasant popping sounds", "enticing aromas"],
          "bugfix" => "1 is no longer equal to 2"
        )
      
        result.join.should == AFTER_HISTORY
      end
    end


  end
end
