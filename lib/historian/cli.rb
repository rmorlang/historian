require 'thor'
require 'project_scout'
#require 'thor/actions'

class Historian::CLI < Thor
  attr_accessor :git

  default_task :help

  def initialize(*)
    super
    repo_directory = ProjectScout.scan Dir.pwd, :for => :git_repository
    self.git = Historian::Git.new(repo_directory, nil)
  end

  desc "commit_msg FILE", "Git commit-msg hook for Historian. Not intended for manual use."
  def commit_msg(message_file)

  end

  desc "install", "install Historian Git hooks into current repository."
  def install
    git.install_hook :commit_msg
    git.install_hook :post_commit
  end

  desc "post_commit", "Git post-commit hook for Historian. Not intended for manual use."
  def post_commit

  end
end

