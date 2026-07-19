# frozen_string_literal: true

# T+1 matching is Active Job on Litejob (in-process). Production should fire
# DailyMatchingJob via host cron / systemd timer, e.g.:
#   0 2 * * * cd /path/to/current && bin/rails runner 'DailyMatchingJob.perform_later("rules")'
# Development/test: call perform_now / perform_later as needed.
