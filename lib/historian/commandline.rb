require 'stringio'
require 'optparse'
require 'ostruct'

module Historian
  class Commandline

REGULAR_COMMANDS = %w( status add maps )
GIT_COMMANDS     = %w( commit post-commit pre-commit )

BANNERS = {
:default => <<EOF,  # -- default banner
Usage: historian [command] [options]

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

:status => <<EOF,# -- status banner
Usage: historian status [release]

Extract formation about the specified release from your history file and
write it to STDOUT. If no release is specified, the first release found
will be used. If no matching releases are found, there will be no output.
EOF
}


    class << self
      def show_default_help
        puts BANNERS[:default]
      end
      def git_command(args)
        command args
      end

      def config
        @config ||= Configuration.new
      end

      def history_file
        "History.txt"
      end

      def invoke_status(option_parser, args)
        option_parser.parse! args
        history = File.open(history_file) do |f|
          parser = Parser.new(f, config)
          status = parser.status *args
          puts status if status
        end
      end

      def invoke_add(option_parser, args)
        option_parser.parse! args
        new_history = nil
        f = if File.exists? history_file
              File.open(history_file)
            else
              StringIO.new
            end
        parser = Parser.new(f, config)
        f.close
        
        additions = args.inject({}) do |memo, arg|
          key, value = arg.split "="
          (memo[key.to_sym] ||= []) << value
          memo
        end
        new_history = parser.add additions
        
        if new_history
          File.open(history_file, "w") do |f|
            f.puts new_history.join
          end
        end
      end

      def invoke_maps(option_parser, args)
        option_parser.parse! args
      end

      def invoke_commit(option_parser, args)
        option_parser.parse! args
      end

      def invoke_pre_commit(option_parser, args)
        option_parser.parse! args
      end

      def invoke_post_commit(option_parser, args)
        option_parser.parse! args
      end

      def command(args)
        command = args.shift
        option_parser = option_parser_for_command command
        method = ("invoke_" + command.gsub(/-/,"_")).to_sym
        send method, option_parser, args
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
      
      def option_parser_for_command command
        option_parser = OptionParser.new do |parser|
          parser.banner = BANNERS[command.to_sym]
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
