require "shellwords"

defaults kamal_proxy_binary: "/usr/local/bin/kamal-proxy",
         kamal_proxy_runtime_dir: "/run/kamal-proxy",
         kamal_proxy_socket_path: "%{kamal_proxy_runtime_dir}/kamal-proxy.sock",
         kamal_proxy_systemd_service: "kamal-proxy.service",
         kamal_proxy_service_name: "%{application}",
         kamal_proxy_app_host: nil,
         kamal_proxy_target_host: "127.0.0.1",
         kamal_proxy_target_port: "%{puma_port}",
         kamal_proxy_health_path: "/up",
         kamal_proxy_tls_cache_path: "/var/lib/kamal-proxy/.config/kamal-proxy/certs"

REQUIRED_DEPLOY_FLAGS = %w[
  --forward-headers
  --health-check-host
  --health-check-path
  --host
  --target
  --tls
  --tls-acme-cache-path
].freeze

SERVICE_NAME_PATTERN = /\A[a-z0-9][a-z0-9_-]{0,62}\z/
HOSTNAME_PATTERN = /\A(?=.{1,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
GATEWAY_STATE_ROOT = "/var/lib/kamal-proxy/"

def check
  validate_contract!

  if dry_run?
    remote.run "test", "-x", binary
    remote.run "systemctl", "is-active", systemd_service
    remote.run "test", "-S", socket_path
    remote.run "test", "-w", socket_path
    REQUIRED_DEPLOY_FLAGS.each { |flag| remote.run(capability_command(flag)) }
    return
  end

  die "GatewayBinaryMissing: expected executable #{binary}" unless remote.run?(
    "test", "-x", binary, silent: true, raise_on_error: false
  )

  die "GatewayServiceInactive: #{systemd_service} is not active; ask the gateway administrator to inspect systemd and journald" unless remote.run?(
    "systemctl", "is-active", systemd_service,
    silent: true, raise_on_error: false
  )

  die "GatewaySocketUnavailable: expected Unix socket #{socket_path}" unless remote.run?(
    "test", "-S", socket_path, silent: true, raise_on_error: false
  )

  die "GatewaySocketUnavailable: #{socket_path} is not writable by #{remote.host.user}; verify kamal-proxy group membership and start a new login session" unless remote.run?(
    "test", "-w", socket_path, silent: true, raise_on_error: false
  )

  REQUIRED_DEPLOY_FLAGS.each do |flag|
    next if remote.run?(capability_command(flag), silent: true, raise_on_error: false)

    die "GatewayBinaryIncompatible: #{binary} does not support required flag #{flag}"
  end
end

def deploy
  validate_contract!
  remote.run(*proxy_command(
    "deploy", service_name,
    "--target=#{target_host}:#{target_port}",
    "--host=#{app_host}",
    "--tls",
    "--tls-acme-cache-path=#{tls_cache_path}",
    "--forward-headers",
    "--health-check-host=#{app_host}",
    "--health-check-path=#{health_path}"
  ))
end

def list
  validate_runtime_dir!
  remote.run(*proxy_command("list"))
end

private

def validate_contract!
  validate_service_name!
  validate_app_host!
  validate_target!
  validate_runtime_dir!
  validate_tls_cache_path!
end

def validate_service_name!
  return if SERVICE_NAME_PATTERN.match?(service_name)

  die "AppIdentityInvalid: application must be 1-63 lowercase ASCII letters, digits, hyphens, or underscores"
end

def validate_app_host!
  return if HOSTNAME_PATTERN.match?(app_host)

  die "AppHostInvalid: APP_HOST must be one ASCII DNS hostname without a scheme, port, wildcard, or path"
end

def validate_target!
  die "AppTargetNotLoopback: puma_host must be exactly 127.0.0.1" unless target_host == "127.0.0.1"
  return if target_port.match?(/\A\d+\z/) && (1..65_535).cover?(target_port.to_i)

  die "AppTargetInvalid: puma_port must be an integer between 1 and 65535"
end

def validate_runtime_dir!
  return if runtime_dir.start_with?("/") && runtime_dir != "/"

  die "GatewaySocketUnavailable: kamal_proxy_runtime_dir must be an absolute non-root path"
end

def validate_tls_cache_path!
  expanded = File.expand_path(tls_cache_path)
  return if expanded.start_with?(GATEWAY_STATE_ROOT) && expanded == tls_cache_path

  die "GatewayTLSPathInvalid: TLS cache must be an absolute path below #{GATEWAY_STATE_ROOT}"
end

def capability_command(flag)
  "#{binary.shellescape} help deploy 2>&1 | grep -F -- #{flag.shellescape} >/dev/null"
end

def proxy_command(*arguments)
  [ "env", "XDG_RUNTIME_DIR=#{runtime_dir}", binary, *arguments ]
end

def binary
  settings.fetch(:kamal_proxy_binary).to_s
end

def runtime_dir
  settings.fetch(:kamal_proxy_runtime_dir).to_s
end

def socket_path
  settings.fetch(:kamal_proxy_socket_path).to_s
end

def systemd_service
  settings.fetch(:kamal_proxy_systemd_service).to_s
end

def service_name
  settings.fetch(:kamal_proxy_service_name).to_s
end

def app_host
  settings.fetch(:kamal_proxy_app_host).to_s
end

def target_host
  settings.fetch(:kamal_proxy_target_host).to_s
end

def target_port
  settings.fetch(:kamal_proxy_target_port).to_s
end

def health_path
  settings.fetch(:kamal_proxy_health_path).to_s
end

def tls_cache_path
  settings.fetch(:kamal_proxy_tls_cache_path).to_s
end
