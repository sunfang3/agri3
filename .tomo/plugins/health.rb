defaults health_check_attempts: 15,
         health_check_delay: 1,
         health_check_host: nil,
         health_check_url: "http://127.0.0.1:%{puma_port}/up"

def check_web
  require_health_check_host!

  if dry_run?
    remote.run(*curl_command)
    return
  end

  settings.fetch(:health_check_attempts).times do |attempt|
    return if remote.run?(*curl_command, silent: true, raise_on_error: false)

    sleep settings.fetch(:health_check_delay) unless final_attempt?(attempt)
  end

  report_web_failure
end

private

def curl_command
  [
    "curl", "--fail", "--silent", "--show-error",
    "--connect-timeout", "1", "--max-time", "3",
    "--header", "Host: #{settings.fetch(:health_check_host)}",
    settings.fetch(:health_check_url)
  ]
end

def require_health_check_host!
  return unless settings.fetch(:health_check_host).to_s.empty?

  die "AppHostInvalid: health_check_host must be configured"
end

def final_attempt?(attempt)
  attempt + 1 == settings.fetch(:health_check_attempts)
end

def report_web_failure
  service = settings.fetch(:puma_systemd_service)
  remote.run "systemctl", "--user", "status", service, raise_on_error: false
  remote.run "journalctl", "-q", "-n", "50", "--user-unit=#{service}",
             raise_on_error: false
  die "puma health check failed for #{settings.fetch(:health_check_url)}"
end
