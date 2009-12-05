require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Historian
  describe Commandline do
    describe "config" do
      it "should return an object with a map method that returns an Array" do
        Commandline.config.should respond_to(:map)
        Commandline.config.map.should be_a_kind_of(Hash)
      end
    end
    describe "parse" do
      before do
        Commandline.stub! :puts
      end

      describe "displaying general help" do
        before do
          Commandline.should_receive :show_default_help
        end
        it "should display help if the first argument is unrecognized" do
          Commandline.should_receive(:puts).with(/unknown command/)
          Commandline.parse %w(zzzzz)
        end
        it "should display help if the first argument is help" do
          Commandline.parse %w(help)
        end
        it "should display help if the first argument is --help" do
          Commandline.parse %w(--help)
        end
        it "should display help if the first argument is -h" do
          Commandline.parse %w(-h)
        end
        it "should display help if the first argument is -?" do
          Commandline.parse %w(-?)
        end
        it "should display help with no arguments" do
          Commandline.parse []          
        end
      end

      describe "handling a generic command" do
        %w( status add maps ).each do |command|
          it "should invoke a regular command when called with #{command}" do
            Commandline.should_not_receive(:git_command).with([command])
            Commandline.should_receive(:command).with([command])
            Commandline.parse [command]
          end
        end
      end

      describe "handling a git-specific command" do
        %w( commit pre-commit post-commit ).each do |command|
          it "should invoke a git command when called with #{command}" do
            Commandline.should_receive(:git_command).with([command])
            Commandline.should_not_receive(:command).with([command])
            Commandline.parse [command]
          end
        end
      end
    end

    describe "git_command" do
      before do
        Commandline.stub! :command
      end
      it "should ensure that the history file is managed by git"
      it "should pass the arguments along to the generic command handler" do
        Commandline.should_receive(:command).with([:foo])
        Commandline.git_command([:foo])
      end
    end

    describe "command" do
      before do
        @command = "no_op"
        @method = ("invoke_" + @command).to_sym
        @command_args = [1,2,3]
        @option_parser = mock("option_parser")
        Commandline.stub! @method => true,
                          :option_parser_for_command => @option_parser
        @args = [@command, @command_args].flatten
        
      end

      it "should call the invoke_<command> method with the command stripped from the args" do
        Commandline.should_receive(@method).with(anything, @command_args)
        Commandline.command @args
      end

      it "should replace dashes with underscores when mapping the command to a method" do
        Commandline.should_receive(@method)
        Commandline.command ["no-op"]
      end

      it "should create a parser for the command" do
        Commandline.should_receive(:option_parser_for_command).with(@command)
        Commandline.command @args
      end

      it "should pass the parser to the invoke method" do 
        Commandline.should_receive(@method).with(@option_parser, anything)
        Commandline.command @args
      end
    end

    %w(status add maps commit pre-commit post-commit).each do |command|
      describe "getting detailed help for a the '#{command}' command" do
        before do
          File.stub! :open
          Commandline.should_receive(:puts).with /Options for #{command} command/
        end
        #it "should display a detailed help screen when invoked with 'help <command>'" do
          #Commandline.parse ["help", command]
        #end
        it "should display a detailed help screen when invoked with 'command -h'" do
          Commandline.parse [command, "-h"]
        end
        it "should display a detailed help screen when invoked with 'command -?'" do
          Commandline.parse [command, "-?"]
        end
        it "should display a detailed help screen when invoked with 'command --help'" do
          Commandline.parse [command, "--help"]
        end
      end

    end

    describe "status" do
      before do
        Commandline.stub! :puts

        @history = File.open(File.expand_path(File.dirname(__FILE__) + '/../example_history.txt'))
        File.stub(:open).and_yield @history

        @parser = mock("parser", :status => true)
        Parser.stub! :new => @parser
      end

      it "should load the history file" do
        File.should_receive(:open).with("History.txt").and_return(@history)
        Commandline.command ["status"]
      end

      it "should create a Parser with the file" do
        Parser.should_receive(:new).with(@history, anything).and_return(@parser)
        Commandline.command ["status"]
      end

      it "should invoke the Parser's status command" do
        @parser.should_receive(:status)
        Commandline.command ["status"]
      end

      it "should pass the release argument to the Parser" do
        @parser.should_receive(:status).with("1.0.0")
        Commandline.command ["status", "1.0.0"]
      end

      it "should display the Parser's output, if any" do
        @parser.stub! :status => "some status"
        Commandline.should_receive(:puts).with("some status")
        Commandline.command ["status"]
      end

      it "should not display anything if no status returned" do
        @parser.stub! :status => nil
        Commandline.should_not_receive(:puts)
        Commandline.command ["status"]
      end
    end
    
    describe "add" do
      before do
        Commandline.stub! :puts

        @history = File.open(File.expand_path(File.dirname(__FILE__) + '/../example_history.txt'))
        File.stub(:open).and_yield @history

        @parser = mock("parser", :add => true)
        Parser.stub! :new => @parser
      end

      xit "should load the history file" do
        File.should_receive(:open).with("History.txt").and_return(@history)
        Commandline.command ["status"]
      end

      xit "should create a Parser with the file" do
        Parser.should_receive(:new).with(@history).and_return(@parser)
        Commandline.command ["status"]
      end

      it "should invoke the Parser's add command" do
        @parser.should_receive(:add)
        Commandline.command ["add"]
      end

      xit "should pass the release argument to the Parser" do
        @parser.should_receive(:status).with("1.0.0")
        Commandline.command ["status", "1.0.0"]
      end

      xit "should display the Parser's output, if any" do
        @parser.stub! :status => "some status"
        Commandline.should_receive(:puts).with("some status")
        Commandline.command ["status"]
      end

      it "should not display anything" do
        Commandline.should_not_receive(:puts)
        Commandline.command ["add"]
      end
    end
  end

end
