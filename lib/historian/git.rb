require 'shellwords'
require 'tempfile'

class Historian::Git
  attr_reader :repo_directory, :history

  def initialize(dir, history)
    @repo_directory = dir
    @history = history
  end

  def tag_release
    ensure_history_has_release
    commit_history_changes if history_dirty?
    Tempfile.open("historian") do |file|
      file.puts commit_message_for_tag
      file.flush
      git "tag", "-a", tag, "-F", file.path
    end
  end

protected

  def commit_history_changes
    Tempfile.open("historian") do |file|
      file.puts commit_message_for_history
      file.flush
      git "add", history.path
      git "commit", history.path, "-F", file.path
    end
  end

  def history_dirty?
    git("status", "--porcelain", history.path) =~ /^.M/
  end

  def tag
    'v' + history.current_version
  end

  def release_name
    history.current_release_name
  end

  def commit_message_for_history
    "update history for release"
  end

  def commit_message_for_tag
    message = "tagged #{tag}"
    if release_name
      message += %{ "#{release_name}"}
    end
    message + "\n\n" + history.release_log
  end

  def ensure_history_has_release
    if !history.changelog.empty?
      history.release
      commit_history_changes
    end
  end

  def git(*args)
    Dir.chdir repo_directory
    %x(git #{args.collect { |a| Shellwords.escape a }.join " "})
  end
end
