def check_ruby
  require_setting :rbenv_ruby_version
  version = settings.fetch(:rbenv_ruby_version)
  command = "rbenv versions --bare | grep -Fx #{version.shellescape}"

  unless remote.run? command, raise_on_error: false
    die "Ruby #{version} is not installed in rbenv on #{remote.host}."
  end

  return if remote.run? "command -v ruby gem bundle >/dev/null",
                        raise_on_error: false

  die "rbenv shims for ruby, gem, and bundle are unavailable on #{remote.host}."
end
