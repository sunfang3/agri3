require "dotenv"

Dotenv.load(File.expand_path("../.env", __dir__))

app_host = ENV.fetch("APP_HOST", "")
application = "agri3"
puma_host = "127.0.0.1"
tomo_user = "web2"
puma_port = Integer("3001")
git_source_repo = "/home/#{tomo_user}/repos/#{application}.git"

hostname_pattern = /\A(?=.{1,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
application_pattern = /\A[a-z0-9][a-z0-9_-]{0,62}\z/

abort "AppEnvironmentMissing: APP_HOST must be set in .env" if app_host.empty?
abort "AppHostInvalid: APP_HOST must be one ASCII DNS hostname" unless hostname_pattern.match?(app_host)
abort "AppIdentityInvalid: application must be a proxy-safe identifier" unless application_pattern.match?(application)
abort "AppTargetNotLoopback: puma_host must be exactly 127.0.0.1" unless puma_host == "127.0.0.1"

plugin "git"
plugin "env"
plugin "bundler"
plugin "rails"
plugin "puma"
plugin "rbenv"
plugin "./plugins/local_git.rb"
plugin "./plugins/health.rb"
plugin "./plugins/runtime.rb"
plugin "./plugins/database.rb"
plugin "./plugins/assets.rb"
plugin "./plugins/kamal_proxy.rb"

host "#{tomo_user}@43.133.189.82", port: 22020
set puma_host: puma_host
set puma_port: puma_port
set health_check_host: app_host
set kamal_proxy_app_host: app_host

set keep_releases: 3
set application: application
set deploy_to: "/home/#{tomo_user}/apps/%{application}"
set git_source_repo: git_source_repo
set git_url: git_source_repo
set git_branch: "master"
set git_exclusions: %w[
  .tomo/
  test/
]
set rbenv_ruby_version: "4.0-jemalloc"
set env_vars: {
  RAILS_ENV: "production",
  RAILS_LOG_TO_STDOUT: "1",
  RAILS_SERVE_STATIC_FILES: "1",
  RBENV_VERSION: "4.0-jemalloc",
  PATH: "/home/#{tomo_user}/.rbenv/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
  RUBY_YJIT_ENABLE: "1",
  BOOTSNAP_CACHE_DIR: "tmp/bootsnap-cache",
  APP_HOST: app_host,
  SECRET_KEY_BASE: :generate_secret
}
# storage/ is linked so Litestack SQLite (data_path) survives deploys.
set linked_dirs: %w[
  log
  public/assets
  storage
  tmp/cache
  tmp/pids
  tmp/sockets
]
set linked_files: %w[
  bin/tailwindcss
]

setup do
  run "kamal_proxy:check"
  run "env:setup"
  run "core:setup_directories"
  run "git:config"
  run "local_git:initialize_source"
  run "git:clone"
  run "git:create_release"
  run "core:symlink_shared"
# run "assets:install_tailwind"
  run "runtime:check_ruby"
  run "bundler:upgrade_bundler"
  run "bundler:config"
  run "bundler:install"
  run "database:create"
  run "rails:db_schema_load"
  run "rails:db_migrate"
  run "rails:db_seed"
  run "puma:setup_systemd"
end

deploy do
  run "kamal_proxy:check"
  run "env:update"
  run "git:create_release"
  run "core:symlink_shared"
  run "core:write_release_json"
  run "bundler:install"
  run "rails:db_migrate"
  run "rails:db_seed"
  run "rails:assets_precompile"
  run "core:symlink_current"
  run "puma:restart"
  run "health:check_web"
  run "kamal_proxy:deploy"
  run "core:clean_releases"
  run "bundler:clean"
  run "core:log_revision"
end
