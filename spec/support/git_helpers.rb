require 'fileutils'
require 'shellwords'

module GitHelpers
  def run_git(*args)
    Dir.chdir repo_directory
    %x(git #{args.collect { |a| Shellwords.escape a }.join " "})
  end

  def tags
    run_git "tag"
  end

  def commits_count
    run_git("log","--pretty=one").split(/\n/).size
  end

  def commit_message_for_tag(tag)
    run_git "show", tag
  end

  def repo_directory
    File.expand_path("../../../tmp/repo", __FILE__)
  end

  def modified?(file)
    base = File.basename file
    !run_git("status", "--porcelain").grep(/#{base}/).empty?
  end

  def create_test_repo
    FileUtils.rm_rf repo_directory
    FileUtils.mkdir_p repo_directory
    run_git "init", repo_directory
    test_file = File.join repo_directory, "test"
    File.open( test_file, "w") { |f| f.puts "foo" }
    run_git "add", test_file
    run_git "commit", "-m", "test commit"
  end

  def history_for_repo(fixture_name)
    @history_file = File.join repo_directory, "History.txt"
    FileUtils.cp fixture_filename(fixture_name), @history_file
    @history = File.open(@history_file, "a+")
    @history.extend Historian::HistoryFile
  end

end
