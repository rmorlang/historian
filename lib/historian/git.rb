require 'shellwords'
require 'tempfile'

class Historian::Git
  attr_reader :repo_directory, :history

  def initialize(dir, history)
    @repo_directory = dir
    @history = history
  end

  def tag_release
    Tempfile.open("historian") do |file|
      file.puts commit_message
      file.flush
      git "tag", "-a", tag, "-F", file.path
    end
  end

protected

  def tag
    'v' + history.current_version
  end

  def release_name
    @history.current_release_name
  end

  def commit_message
    message = "tagged #{tag}"
    if !release_name.empty?
      message += %{ "#{release_name}"}
    end
    message + "\n\n" + @history.release_log
  end

  def git(*args)
    Dir.chdir repo_directory
    %x(git #{args.collect { |a| Shellwords.escape a }.join " "})
  end
end
