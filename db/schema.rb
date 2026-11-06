# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_31_000000) do
  create_table "active_storage_attachments", id: :integer, default: nil, force: :cascade do |t|
    t.integer "blob_id", null: false
    t.text "created_at", limit: 6, null: false
    t.text "name", null: false
    t.integer "record_id", null: false
    t.text "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :integer, default: nil, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.text "checksum"
    t.text "content_type"
    t.text "created_at", limit: 6, null: false
    t.text "filename", null: false
    t.text "key", null: false
    t.text "metadata"
    t.text "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :integer, default: nil, force: :cascade do |t|
    t.integer "blob_id", null: false
    t.text "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
    t.index ["blob_id"], name: "index_active_storage_variant_records_on_blob_id"
  end

  create_table "admins", id: :integer, default: nil, force: :cascade do |t|
    t.text "created_at", limit: 6, null: false
    t.integer "district_id"
    t.text "email", null: false
    t.text "name", null: false
    t.text "password_digest", null: false
    t.text "role", default: "district", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["district_id"], name: "index_admins_on_district_id"
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "alerts", id: :integer, default: nil, force: :cascade do |t|
    t.text "body"
    t.text "created_at", limit: 6, null: false
    t.integer "district_id"
    t.text "severity", default: "medium"
    t.bigint "source_id"
    t.text "source_type"
    t.text "status", default: "open"
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["district_id"], name: "index_alerts_on_district_id"
  end

  create_table "analytics_events", id: :integer, default: nil, force: :cascade do |t|
    t.text "action_name"
    t.bigint "actor_id"
    t.text "actor_type"
    t.text "created_at", limit: 6, null: false
    t.text "district_code"
    t.text "event_type", null: false
    t.text "page"
    t.text "payload", default: "{}"
    t.text "updated_at", limit: 6, null: false
    t.index ["actor_type", "actor_id"], name: "index_analytics_events_on_actor_type_and_actor_id"
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
  end

  create_table "app_messages", id: :integer, default: nil, force: :cascade do |t|
    t.text "body"
    t.text "created_at", limit: 6, null: false
    t.text "message_type", default: "system"
    t.text "read_at", limit: 6
    t.integer "student_id", null: false
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["student_id", "read_at"], name: "index_app_messages_on_student_id_and_read_at"
    t.index ["student_id"], name: "index_app_messages_on_student_id"
  end

  create_table "attributions", id: :integer, default: nil, force: :cascade do |t|
    t.text "contribution", default: "0"
    t.text "created_at", limit: 6, null: false
    t.text "details", default: "{}"
    t.bigint "matchable_id"
    t.text "matchable_type"
    t.text "outcome_type", null: false
    t.integer "student_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["student_id"], name: "index_attributions_on_student_id"
  end

  create_table "capability_assessments", id: :integer, default: nil, force: :cascade do |t|
    t.text "assessed_on", null: false
    t.text "created_at", limit: 6, null: false
    t.text "scores", default: "{}", null: false
    t.integer "student_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["student_id"], name: "index_capability_assessments_on_student_id"
  end

  create_table "chat_messages", id: :integer, default: nil, force: :cascade do |t|
    t.text "author", null: false
    t.text "body", null: false
    t.text "created_at", limit: 6, null: false
    t.text "room", default: "lobby", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["room", "created_at", "id"], name: "index_chat_messages_on_room_and_created_at_and_id"
  end

  create_table "check_ins", id: :integer, default: nil, force: :cascade do |t|
    t.text "checked_in_at", limit: 6, null: false
    t.integer "course_id", null: false
    t.text "created_at", limit: 6, null: false
    t.text "distance_meters"
    t.integer "enrollment_id", null: false
    t.integer "gps_valid", default: 0, null: false
    t.text "latitude"
    t.text "longitude"
    t.integer "student_id", null: false
    t.text "token", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["course_id"], name: "index_check_ins_on_course_id"
    t.index ["enrollment_id", "checked_in_at"], name: "index_check_ins_on_enrollment_id_and_checked_in_at"
    t.index ["enrollment_id"], name: "index_check_ins_on_enrollment_id"
    t.index ["student_id"], name: "index_check_ins_on_student_id"
  end

  create_table "course_tags", id: :integer, default: nil, force: :cascade do |t|
    t.integer "course_id", null: false
    t.text "created_at", limit: 6, null: false
    t.integer "tag_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["course_id", "tag_id"], name: "index_course_tags_on_course_id_and_tag_id", unique: true
    t.index ["course_id"], name: "index_course_tags_on_course_id"
    t.index ["tag_id"], name: "index_course_tags_on_tag_id"
  end

  create_table "courses", id: :integer, default: nil, force: :cascade do |t|
    t.integer "capacity"
    t.text "created_at", limit: 6, null: false
    t.text "deep_tags", default: "[]"
    t.text "description"
    t.integer "district_id"
    t.text "ends_at", limit: 6
    t.text "latitude"
    t.text "longitude"
    t.integer "mentor_id"
    t.text "mentor_name"
    t.text "place"
    t.integer "published", default: 1, null: false
    t.text "starts_at", limit: 6
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["district_id"], name: "index_courses_on_district_id"
    t.index ["mentor_id"], name: "index_courses_on_mentor_id"
  end

  create_table "district_stats_snapshots", primary_key: "district_id", id: :integer, default: nil, force: :cascade do |t|
    t.text "district_name", null: false
    t.integer "enrolled_count", default: 0, null: false
    t.text "refreshed_at"
    t.integer "student_count", default: 0, null: false
  end

  create_table "districts", id: :integer, default: nil, force: :cascade do |t|
    t.integer "active", default: 1, null: false
    t.text "code", null: false
    t.text "created_at", limit: 6, null: false
    t.text "name", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["code"], name: "index_districts_on_code", unique: true
  end

  create_table "enrollments", id: :integer, default: nil, force: :cascade do |t|
    t.text "confirmed_at", limit: 6
    t.integer "course_id", null: false
    t.text "created_at", limit: 6, null: false
    t.integer "district_ack_admin_id"
    t.text "district_ack_status", default: "not_required", null: false
    t.text "district_acked_at", limit: 6
    t.text "status", default: "pending", null: false
    t.integer "student_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["district_ack_status"], name: "index_enrollments_on_district_ack_status"
    t.index ["status"], name: "index_enrollments_on_status"
    t.index ["student_id", "course_id"], name: "index_enrollments_on_student_id_and_course_id", unique: true
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "feedback_signals", id: :integer, default: nil, force: :cascade do |t|
    t.text "created_at", limit: 6, null: false
    t.bigint "matchable_id", null: false
    t.text "matchable_type", null: false
    t.text "signal_type", null: false
    t.integer "student_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.text "weight", default: "1.0"
    t.index ["matchable_type", "matchable_id"], name: "index_feedback_signals_on_matchable_type_and_matchable_id"
    t.index ["student_id"], name: "index_feedback_signals_on_student_id"
  end

  create_table "honors", id: :integer, default: nil, force: :cascade do |t|
    t.text "awarded_on"
    t.text "created_at", limit: 6, null: false
    t.text "status", default: "pending", null: false
    t.integer "student_id", null: false
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["student_id"], name: "index_honors_on_student_id"
  end

  create_table "knowledge_articles", id: :integer, default: nil, force: :cascade do |t|
    t.text "body", null: false
    t.text "category"
    t.text "created_at", limit: 6, null: false
    t.integer "published", default: 1, null: false
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
  end

  create_table "match_weights", id: :integer, default: nil, force: :cascade do |t|
    t.text "created_at", limit: 6, null: false
    t.text "tag_category", null: false
    t.text "updated_at", limit: 6, null: false
    t.text "weight", default: "1.0", null: false
    t.index ["tag_category"], name: "index_match_weights_on_tag_category", unique: true
  end

  create_table "mentor_answers", id: :integer, default: nil, force: :cascade do |t|
    t.text "answer_text"
    t.text "audio_key"
    t.text "created_at", limit: 6, null: false
    t.integer "mentor_id"
    t.text "question", null: false
    t.text "status", default: "open"
    t.integer "student_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["mentor_id"], name: "index_mentor_answers_on_mentor_id"
    t.index ["student_id"], name: "index_mentor_answers_on_student_id"
  end

  create_table "mentors", id: :integer, default: nil, force: :cascade do |t|
    t.text "bio"
    t.text "created_at", limit: 6, null: false
    t.text "deep_tags", default: "[]"
    t.integer "district_id"
    t.text "name", null: false
    t.text "phone"
    t.text "specialty"
    t.text "updated_at", limit: 6, null: false
    t.index ["district_id"], name: "index_mentors_on_district_id"
  end

  create_table "policies", id: :integer, default: nil, force: :cascade do |t|
    t.text "content_text"
    t.text "created_at", limit: 6, null: false
    t.integer "district_id"
    t.text "document_number"
    t.text "issuing_authority"
    t.text "parse_status", default: "manual"
    t.text "parsed_fields", default: "{}"
    t.text "pdf_text"
    t.integer "published", default: 1, null: false
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
    t.text "valid_until"
    t.index ["district_id"], name: "index_policies_on_district_id"
  end

  create_table "policy_interactions", id: :integer, default: nil, force: :cascade do |t|
    t.text "application_status", default: "none", null: false
    t.text "created_at", limit: 6, null: false
    t.integer "policy_id", null: false
    t.integer "saved", default: 0, null: false
    t.integer "student_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.text "viewed_at", limit: 6
    t.index ["policy_id"], name: "index_policy_interactions_on_policy_id"
    t.index ["student_id", "policy_id"], name: "index_policy_interactions_on_student_id_and_policy_id", unique: true
    t.index ["student_id"], name: "index_policy_interactions_on_student_id"
  end

  create_table "policy_tags", id: :integer, default: nil, force: :cascade do |t|
    t.text "created_at", limit: 6, null: false
    t.integer "policy_id", null: false
    t.integer "tag_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["policy_id", "tag_id"], name: "index_policy_tags_on_policy_id_and_tag_id", unique: true
    t.index ["policy_id"], name: "index_policy_tags_on_policy_id"
    t.index ["tag_id"], name: "index_policy_tags_on_tag_id"
  end

  create_table "push_deliveries", id: :integer, default: nil, force: :cascade do |t|
    t.text "body"
    t.text "channel", null: false
    t.text "created_at", limit: 6, null: false
    t.text "payload", default: "{}"
    t.text "sent_at", limit: 6
    t.text "status", default: "queued"
    t.integer "student_id", null: false
    t.text "template_key"
    t.text "title"
    t.text "updated_at", limit: 6, null: false
    t.index ["student_id"], name: "index_push_deliveries_on_student_id"
  end

  create_table "resource_gaps", id: :integer, default: nil, force: :cascade do |t|
    t.text "created_at", limit: 6, null: false
    t.integer "demand_count", default: 0
    t.text "description"
    t.integer "district_id"
    t.text "gap_type", null: false
    t.text "industry"
    t.text "severity", default: "medium"
    t.integer "supply_count", default: 0
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["district_id"], name: "index_resource_gaps_on_district_id"
  end

  create_table "resource_matches", id: :integer, default: nil, force: :cascade do |t|
    t.text "cosine_similarity"
    t.text "created_at", limit: 6, null: false
    t.text "engine", default: "rules", null: false
    t.bigint "matchable_id", null: false
    t.text "matchable_type", null: false
    t.text "reason_tags", default: "[]"
    t.integer "score", default: 0, null: false
    t.text "status", default: "recommended", null: false
    t.integer "student_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["student_id", "matchable_type", "matchable_id"], name: "idx_resource_matches_unique", unique: true
    t.index ["student_id", "score"], name: "index_resource_matches_on_student_id_and_score"
    t.index ["student_id"], name: "index_resource_matches_on_student_id"
  end

  create_table "showcase_cases", id: :integer, default: nil, force: :cascade do |t|
    t.text "body"
    t.integer "contribution_score", default: 0, null: false
    t.text "created_at", limit: 6, null: false
    t.integer "district_id"
    t.integer "published", default: 0, null: false
    t.integer "student_id", null: false
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["district_id"], name: "index_showcase_cases_on_district_id"
    t.index ["student_id"], name: "index_showcase_cases_on_student_id"
  end

  create_table "student_needs", id: :integer, default: nil, force: :cascade do |t|
    t.text "body", null: false
    t.text "created_at", limit: 6, null: false
    t.text "response"
    t.text "status", default: "pending", null: false
    t.integer "student_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["student_id"], name: "index_student_needs_on_student_id"
  end

  create_table "student_tags", id: :integer, default: nil, force: :cascade do |t|
    t.text "created_at", limit: 6, null: false
    t.integer "student_id", null: false
    t.integer "tag_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.integer "user_corrected", default: 0, null: false
    t.index ["student_id", "tag_id"], name: "index_student_tags_on_student_id_and_tag_id", unique: true
    t.index ["student_id"], name: "index_student_tags_on_student_id"
    t.index ["tag_id"], name: "index_student_tags_on_tag_id"
  end

  create_table "students", id: :integer, default: nil, force: :cascade do |t|
    t.text "annual_income"
    t.text "created_at", limit: 6, null: false
    t.integer "district_id", null: false
    t.text "honors"
    t.text "name", null: false
    t.text "password_digest"
    t.text "phone", null: false
    t.text "primary_industry"
    t.text "profile", default: "{}"
    t.text "scale"
    t.text "tips_stage", default: "T"
    t.text "updated_at", limit: 6, null: false
    t.index ["district_id"], name: "index_students_on_district_id"
    t.index ["phone"], name: "index_students_on_phone", unique: true
    t.index ["tips_stage"], name: "index_students_on_tips_stage"
  end

  create_table "survey_responses", id: :integer, default: nil, force: :cascade do |t|
    t.text "answers", default: "{}"
    t.text "created_at", limit: 6, null: false
    t.integer "score"
    t.integer "student_id", null: false
    t.integer "survey_id", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["student_id"], name: "index_survey_responses_on_student_id"
    t.index ["survey_id", "student_id"], name: "index_survey_responses_on_survey_id_and_student_id", unique: true
    t.index ["survey_id"], name: "index_survey_responses_on_survey_id"
  end

  create_table "surveys", id: :integer, default: nil, force: :cascade do |t|
    t.integer "active", default: 1, null: false
    t.integer "course_id"
    t.text "created_at", limit: 6, null: false
    t.text "questions", default: "[]"
    t.text "survey_type", null: false
    t.text "title", null: false
    t.text "updated_at", limit: 6, null: false
    t.index ["course_id"], name: "index_surveys_on_course_id"
  end

  create_table "tags", id: :integer, default: nil, force: :cascade do |t|
    t.text "category", null: false
    t.text "created_at", limit: 6, null: false
    t.text "name", null: false
    t.text "updated_at", limit: 6, null: false
    t.text "value"
    t.index ["category", "name"], name: "index_tags_on_category_and_name", unique: true
  end

  create_table "tips_stage_rules", id: :integer, default: nil, force: :cascade do |t|
    t.text "conditions", default: "{}", null: false
    t.text "created_at", limit: 6, null: false
    t.integer "enabled", default: 1, null: false
    t.text "name", null: false
    t.integer "priority", default: 0, null: false
    t.text "stage", null: false
    t.text "updated_at", limit: 6, null: false
  end

  create_table "training_photos", id: :integer, default: nil, force: :cascade do |t|
    t.integer "admin_id"
    t.text "caption"
    t.integer "course_id", null: false
    t.text "created_at", limit: 6, null: false
    t.text "latitude"
    t.text "longitude"
    t.text "storage_key"
    t.integer "student_id"
    t.text "taken_at", limit: 6
    t.text "updated_at", limit: 6, null: false
    t.text "watermark_text"
    t.index ["admin_id"], name: "index_training_photos_on_admin_id"
    t.index ["course_id"], name: "index_training_photos_on_course_id"
    t.index ["student_id"], name: "index_training_photos_on_student_id"
  end

  create_table "voice_notes", id: :integer, default: nil, force: :cascade do |t|
    t.text "audio_key"
    t.integer "course_id"
    t.text "created_at", limit: 6, null: false
    t.text "status", default: "pending"
    t.text "structured", default: "{}"
    t.integer "student_id", null: false
    t.text "transcript"
    t.text "updated_at", limit: 6, null: false
    t.index ["course_id"], name: "index_voice_notes_on_course_id"
    t.index ["student_id"], name: "index_voice_notes_on_student_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admins", "districts"
  add_foreign_key "alerts", "districts"
  add_foreign_key "app_messages", "students"
  add_foreign_key "attributions", "students"
  add_foreign_key "capability_assessments", "students"
  add_foreign_key "check_ins", "courses"
  add_foreign_key "check_ins", "enrollments"
  add_foreign_key "check_ins", "students"
  add_foreign_key "course_tags", "courses"
  add_foreign_key "course_tags", "tags"
  add_foreign_key "courses", "districts"
  add_foreign_key "courses", "mentors"
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "students"
  add_foreign_key "feedback_signals", "students"
  add_foreign_key "honors", "students"
  add_foreign_key "mentor_answers", "mentors"
  add_foreign_key "mentor_answers", "students"
  add_foreign_key "mentors", "districts"
  add_foreign_key "policies", "districts"
  add_foreign_key "policy_interactions", "policies"
  add_foreign_key "policy_interactions", "students"
  add_foreign_key "policy_tags", "policies"
  add_foreign_key "policy_tags", "tags"
  add_foreign_key "push_deliveries", "students"
  add_foreign_key "resource_gaps", "districts"
  add_foreign_key "resource_matches", "students"
  add_foreign_key "showcase_cases", "districts"
  add_foreign_key "showcase_cases", "students"
  add_foreign_key "student_needs", "students"
  add_foreign_key "student_tags", "students"
  add_foreign_key "student_tags", "tags"
  add_foreign_key "students", "districts"
  add_foreign_key "survey_responses", "students"
  add_foreign_key "survey_responses", "surveys"
  add_foreign_key "surveys", "courses"
  add_foreign_key "training_photos", "admins"
  add_foreign_key "training_photos", "courses"
  add_foreign_key "training_photos", "students"
  add_foreign_key "voice_notes", "courses"
  add_foreign_key "voice_notes", "students"
end
