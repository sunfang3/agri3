# Litestack deploy helpers: GitHub Packages credentials for bundler + optional extensions.
# Packages host: https://rubygems.pkg.github.com/sunfang3 (litestack + honker).

require "yaml"
require "shellwords"

# Litecache/Litejob/Litecable open files under storage/<env>/ during boot (e.g.
# storage/production/cache.sqlite3). Litesupport.root mkdir_p's the AR path, but
# cache/job/cable paths do not — missing dirs raise SQLite3::CantOpenException
# on `rake db:create` / environment load. Create env dirs under shared storage
# (linked into each release as storage/).
def ensure_storage_dirs
  return if dry_run?

  %w[development test production].each do |env|
    remote.mkdir_p paths.shared.join("storage", env)
  end
end

def configure_packages_credentials
  # bundler:config overwrites release .bundle/config with only Tomo settings.
  # Merge Packages auth so `bundle install` can resolve rubygems.pkg.github.com
  # even if envrc is not sourced for the SSH session.
  return if dry_run?

  env_file = paths.env.to_s
  auth = remote.capture(
    "bash", "-c",
    "set -a; [ -f #{env_file.shellescape} ] && . #{env_file.shellescape}; set +a; " \
    "printf %s \"${BUNDLE_RUBYGEMS__PKG__GITHUB__COM:-}\"",
    raise_on_error: false,
    echo: false,
    silent: true
  ).to_s.strip

  if auth.empty? || !auth.include?(":")
    die <<~REASON
      GitHub Packages credentials missing on the remote host.
      Ensure env_vars includes BUNDLE_RUBYGEMS__PKG__GITHUB__COM (set from PAT
      when evaluating .tomo/config.rb) and re-run env:setup / env:update.
    REASON
  end

  config_path = paths.release.join(".bundle/config")
  remote.mkdir_p config_path.dirname

  existing = remote.capture("cat", config_path, raise_on_error: false, echo: false, silent: true).to_s
  data =
    if existing.strip.empty?
      {}
    else
      loaded = YAML.safe_load(existing, permitted_classes: [Symbol], aliases: true)
      loaded.is_a?(Hash) ? loaded : {}
    end
  data["BUNDLE_RUBYGEMS__PKG__GITHUB__COM"] = auth

  remote.write(text: YAML.dump(data), to: config_path)
end

def fetch_extensions
  # Optional SQLite loadable extensions into the release vendor/ (not shared storage).
  # Dev machines may have fetched darwin builds; production is linux — always re-fetch here.
  return if dry_run?

  release = paths.release.to_s
  remote.run(
    "bash", "-c",
    [
      "set -euo pipefail",
      "cd #{release.shellescape}",
      "export LITESTACK_EXTENSION_ROOT=\"$PWD\"",
      "GEM_ROOT=\"$(bundle show litestack)\"",
      "if [ -f \"$GEM_ROOT/scripts/fetch_simple.rb\" ]; then",
      "  bundle exec ruby \"$GEM_ROOT/scripts/fetch_simple.rb\" || true",
      "fi",
      "if [ -f \"$GEM_ROOT/scripts/fetch_vectorlite.rb\" ]; then",
      "  bundle exec ruby \"$GEM_ROOT/scripts/fetch_vectorlite.rb\" || true",
      "fi"
    ].join("\n")
  )
end
