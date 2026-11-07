hooks.register(:env_infection_post) do
  Rails.application.eager_load!
end

# One worker uses a fresh database prepared by bin/mutant. Reconnect after fork;
# never inherit a live SQLite connection from the parent process.
hooks.register(:setup_integration_post) do
  ActiveRecord::Base.connection_handler.clear_all_connections!
end
