
require 'optparse'

module Historian
  class Commandline

REGULAR_COMMANDS = %w( status add maps )
GIT_COMMANDS     = %w( commit post-commit pre-commit )

    
BANNER_HEAD = <<EOF
Usage: historian [command] [options]

EOF
BANNER_DEFAULT = <<EOF
General Commands:
  status    Display the changelog for a release.
  add       Add new history to the current, in-progress release.
  maps      Display all configured keyword-to-section-name mappings.
  help      Detailed usage information for a specified command.

Commands For Use With Git:
** See the documentation regarding Git integration.

  commit      Commit any outstanding changes to the current history.
  pre-commit  Invoke historian as a git pre-commit filter.
  post-commit Invoke historian as a git post-commit filter.
EOF


    class << self
      def show_default_help
        puts BANNER_HEAD + BANNER_DEFAULT
      end
      def git_command(args)
        command args
      end

      def invoke_status(parser, args)
        parser.parse! args
      end
      def invoke_add(parser, args)
        parser.parse! args
      end
      def invoke_maps(parser, args)
        parser.parse! args
      end
      def invoke_commit(parser, args)
        parser.parse! args
      end
      def invoke_pre_commit(parser, args)
        parser.parse! args
      end
      def invoke_post_commit(parser, args)
        parser.parse! args
      end

      def command(args)
        command = args.shift
        parser = parser_for_command command
        method = ("invoke_" + command.gsub(/-/,"_")).to_sym
        send method, parser, args
      end

      def unknown_command(command)
        puts "unknown command #{command}"
        show_default_help
      end

      def parse(options)
        if options.empty? ||  %w(-h -? --help).include?(options.first)
          return show_default_help
        elsif options.first == "help" && options.count > 1
          options = [ options[1], "--help" ]
        end

        case options.first
        when *REGULAR_COMMANDS
          command options
        when *GIT_COMMANDS
          git_command options
        else
          return unknown_command(options.first)
        end
      end

      protected
      
      def parser_for_command command
        parser = OptionParser.new do |parser|
          parser.banner = BANNER_HEAD
          parser.separator " "
          parser.separator "Options for #{command} command:"
          parser.on_tail("--help", "-h", "-?", "Show this help screen") do
            puts parser.to_s
          end
        end
      end
    end
  end
end
