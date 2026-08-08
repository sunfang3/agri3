# frozen_string_literal: true

require "test_helper"

class SchemaPortTest < ActiveSupport::TestCase
  CORE = %w[
    districts admins students tags student_tags policies policy_tags mentors courses
    course_tags enrollments resource_matches analytics_events app_messages tips_stage_rules
    check_ins training_photos voice_notes push_deliveries surveys survey_responses
    feedback_signals match_weights resource_gaps alerts attributions showcase_cases
    knowledge_articles mentor_answers chat_messages
  ].freeze

  test "business schema tables exist without pg/pgbus/solid infrastructure tables" do
    tables = ActiveRecord::Base.connection.tables
    CORE.each { |t| assert_includes tables, t, "missing #{t}" }
    forbidden = tables.grep(/pgbus|pgmq|solid_/)
    assert_empty forbidden, "unexpected infra tables: #{forbidden}"
  end

  test "schema.rb has no jsonb or tsvector" do
    schema = File.read(Rails.root.join("db/schema.rb"))
    refute_match(/\bjsonb\b/, schema)
    refute_match(/\btsvector\b/, schema)
    refute_match(/\bpgmq\b/, schema)
  end
end
