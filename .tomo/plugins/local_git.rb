def initialize_source
  source_repo = settings.fetch(:git_source_repo).to_s
  return if dry_run?
  return if remote.run?("test", "-d", source_repo, silent: true, raise_on_error: false)

  remote.mkdir_p File.dirname(source_repo)
  remote.run "git", "init", "--bare", source_repo
end
