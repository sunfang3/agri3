defaults tailwind_cli_url: "https://github.com/dobicinaitis/tailwind-cli-extra/releases/download/v2.9.4/tailwindcss-extra-linux-x64"

def install_tailwind
  target = paths.shared.join("bin/tailwindcss")
  return if !dry_run? && remote.run?("test", "-x", target, silent: true)

  remote.mkdir_p target.dirname
  remote.run "curl", "-fsSL", "-o", target, settings.fetch(:tailwind_cli_url)
  remote.run "chmod", "+x", target
end
