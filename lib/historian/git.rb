require 'shellwords'
require 'tempfile'
require 'fileutils'

class Historian::Git
  class Hooker
    attr_accessor :hook, :repo_dir

    def initialize(repo_dir, hook)
      self.repo_dir = repo_dir
      self.hook = hook
    end

    def create_hook_script
      File.open(hook_script, "w") do |f|
        f.puts "#!/bin/bash"
        f.puts "bundle exec historian #{hook.to_s} $@"
      end
      File.chmod 0755, hook_script
    end

    def create_hook_scripts_dir
      Dir.mkdir hook_scripts_dir unless File.directory? hook_scripts_dir
    end

    def create_hook_wrapper_script
      File.open(hook_wrapper_script, "w") do |f|
        script = <<-EOF
          #!/bin/bash
          #
          # Git hook modified by Historian. Do not modify this file.
          # Add more hooks in the #{hook_to_git}.d directory.
          #
          BASE=`dirname $0`
          for S in $BASE/#{hook_to_git}.d/*
          do
          echo $S
          $S $@ || exit $?
          done
        EOF
        f.puts script.gsub(/^\s+/,'')
      end
      File.chmod 0755, hook_wrapper_script
    end

    def other_git_hook_exists?
      File.exists?(hook_wrapper_script) && !File.directory?(hook_scripts_dir)
    end

    def hook_script
      File.join hook_scripts_dir, "historian"
    end

    def hook_scripts_dir
      File.join hooks_dir, hook_to_git + ".d"
    end

    def hook_to_git
      hook.to_s.gsub "_", "-"
    end

    def hook_wrapper_script
      File.join hooks_dir, hook_to_git
    end

    def hooks_dir
      File.join repo_dir, ".git", "hooks"
    end

    def install
      create_hook_scripts_dir
      create_hook_script
      create_hook_wrapper_script
    end

    def installed?
      File.exists? hook_script
    end

    def preserve_original
      create_hook_scripts_dir
      FileUtils.cp hook_wrapper_script, File.join(hook_scripts_dir, "original")
    end
  end


  attr_reader :repo_directory, :history

  def bundle_history_file
    amend_history_changes
  end

  def initialize(dir, history)
    @repo_directory = dir
    @history = history
  end

  def install_hook(hook)
    hook = Hooker.new(repo_directory, hook)
    if hook.other_git_hook_exists?
      hook.preserve_original
      hook.install
      :adapted
    elsif !hook.installed?
      hook.install
      :created
    else
      :exists
    end
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

  def amend_history_changes
    Tempfile.open("historian") do |file|
      git "add", history.path
      git "commit", history.path, "--amend", "-C", "HEAD"
    end
  end

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

  def hook_invokes_command?(command)
    return false unless File.exists?(hook_script_for command)
    lines = File.readlines(hook_script_for command).collect { |l| l.chomp }
    lines.first == "#!/bin/bash" && lines.grep("bundle exec historian #{command} $@")
  end

  def hook_script_for(hook)
    File.join repo_directory, ".git/hooks", hook.to_s.gsub("_", "-")
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
