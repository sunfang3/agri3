ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Use the system Tailwind CLI exposed through bin/tailwindcss.
ENV["TAILWINDCSS_INSTALL_DIR"] ||= File.expand_path("../bin", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
