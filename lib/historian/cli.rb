require 'thor'
require 'project_scout'
#require 'thor/actions'

class Historian::CLI < Thor
  attr_accessor :git, :history, :repo_directory

  default_task :help

  def initialize(*)
    super
    @repo_directory = ProjectScout.scan Dir.pwd, :for => [ :git_repository ]

    history_file = File.join(repo_directory, "History.txt")
    unless File.exists? history_file
      File.open history_file, "w"
    end
    @history = File.open history_file, File::RDWR
    history.sync = true
    history.extend Historian::HistoryFile
    self.git = Historian::Git.new(repo_directory, history)
  end

  desc "commit_msg FILE", "Git commit-msg hook for Historian. Not intended for manual use."
  def commit_msg(message_file)
    return nil if File.exists? amend_flag_file

    history_updated = false
    release = nil
    new_message = []
    File.open(message_file).each_line do |line|
      line = Historian::CommitMessage.parse_line line
      new_message << line.to_s unless line.suppressed?
      case line.significance
      when :minor, :major, :patch
        history.update_history line.significance => line.to_message_s
        history_updated = true
      when :release
        release = line.to_message_s
      end
    end

    if release
      history_updated = true
      history.update_history :release => release
      File.open release_flag_file, "w"
    end

    if history_updated
      File.open amend_flag_file, "w"
      File.open(message_file,"w") { |f| f.puts new_message }
    end
  end

  desc "install", "install Historian Git hooks into current repository."
  def install
    git.install_hook :commit_msg
    git.install_hook :post_commit
  end

  desc "post_commit", "Git post-commit hook for Historian. Not intended for manual use."
  def post_commit
    if File.exists? amend_flag_file
      File.unlink amend_flag_file
      git.bundle_history_file
    end

    if File.exists? release_flag_file
      File.unlink release_flag_file
      git.tag_release
    end
  end

protected

  def amend_flag_file
    File.join(repo_directory, ".git", "historian-amend")
  end

  def release_flag_file
    File.join(repo_directory, ".git", "historian-release")
  end
end

