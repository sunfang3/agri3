# frozen_string_literal: true

class CreatePlatformCore < ActiveRecord::Migration[8.1]
  def change
    create_table :districts do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :districts, :code, unique: true

    create_table :admins do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, default: "district", null: false # district | city | system
      t.references :district, foreign_key: true
      t.timestamps
    end
    add_index :admins, :email, unique: true

    create_table :students do |t|
      t.string :phone, null: false
      t.string :name, null: false
      t.references :district, null: false, foreign_key: true
      t.string :primary_industry # 主业
      t.string :scale
      t.string :annual_income
      t.text :honors # 已获荣誉
      t.string :tips_stage, default: "T" # T-I-P-S dynamic stage
      t.json :profile, default: "{}"
      t.string :password_digest
      t.timestamps
    end
    add_index :students, :phone, unique: true
    add_index :students, :tips_stage

    create_table :tags do |t|
      t.string :name, null: false
      t.string :category, null: false # applicable_object | industry | scale_threshold | income_threshold | deadline | course | other
      t.string :value
      t.timestamps
    end
    add_index :tags, [ :category, :name ], unique: true

    create_table :student_tags do |t|
      t.references :student, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.boolean :user_corrected, default: false, null: false
      t.timestamps
    end
    add_index :student_tags, [ :student_id, :tag_id ], unique: true

    create_table :policies do |t|
      t.string :title, null: false
      t.text :content_text
      t.date :valid_until
      t.string :pdf_text # stored extracted text from PDF
      t.string :parse_status, default: "manual" # manual | pending_review | approved
      t.json :parsed_fields, default: "{}"
      t.references :district, foreign_key: true # nil = city-wide
      t.boolean :published, default: true, null: false
      t.timestamps
    end

    create_table :policy_tags do |t|
      t.references :policy, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :policy_tags, [ :policy_id, :tag_id ], unique: true

    create_table :mentors do |t|
      t.string :name, null: false
      t.string :phone
      t.string :specialty
      t.text :bio
      t.json :deep_tags, default: "[]"
      t.references :district, foreign_key: true
      t.timestamps
    end

    create_table :courses do |t|
      t.string :title, null: false
      t.text :description
      t.string :mentor_name
      t.references :mentor, foreign_key: true
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :place
      t.string :latitude
      t.string :longitude
      t.references :district, foreign_key: true
      t.json :deep_tags, default: "[]"
      t.boolean :published, default: true, null: false
      t.timestamps
    end

    create_table :course_tags do |t|
      t.references :course, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :course_tags, [ :course_id, :tag_id ], unique: true

    create_table :enrollments do |t|
      t.references :student, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :status, default: "pending", null: false # pending | enrolled | completed | dropped
      t.datetime :confirmed_at
      t.timestamps
    end
    add_index :enrollments, [ :student_id, :course_id ], unique: true
    add_index :enrollments, :status

    create_table :resource_matches do |t|
      t.references :student, null: false, foreign_key: true
      t.string :matchable_type, null: false # Policy | Course
      t.bigint :matchable_id, null: false
      t.integer :score, null: false, default: 0 # 0-100
      t.string :status, default: "recommended", null: false # recommended | viewed | applied | dismissed
      t.string :engine, default: "rules", null: false # rules | cosine
      t.json :reason_tags, default: "[]"
      t.string :cosine_similarity
      t.timestamps
    end
    add_index :resource_matches, [ :student_id, :matchable_type, :matchable_id ], unique: true, name: "idx_resource_matches_unique"
    add_index :resource_matches, [ :student_id, :score ]

    create_table :analytics_events do |t|
      t.string :event_type, null: false # login | key_action | page_view
      t.string :actor_type # Student | Admin
      t.bigint :actor_id
      t.string :page
      t.string :action_name
      t.json :payload, default: "{}"
      t.string :district_code
      t.timestamps
    end
    add_index :analytics_events, :event_type
    add_index :analytics_events, [ :actor_type, :actor_id ]
    add_index :analytics_events, :created_at

    create_table :app_messages do |t|
      t.references :student, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.string :message_type, default: "system"
      t.datetime :read_at
      t.timestamps
    end
    add_index :app_messages, [ :student_id, :read_at ]

    create_table :tips_stage_rules do |t|
      t.string :stage, null: false # T | I | P | S
      t.string :name, null: false
      t.json :conditions, default: "{}", null: false
      t.integer :priority, default: 0, null: false
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    create_table :check_ins do |t|
      t.references :enrollment, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :token, null: false
      t.string :latitude
      t.string :longitude
      t.boolean :gps_valid, default: false, null: false
      t.string :distance_meters
      t.datetime :checked_in_at, null: false
      t.timestamps
    end
    add_index :check_ins, [ :enrollment_id, :checked_in_at ]

    create_table :training_photos do |t|
      t.references :course, null: false, foreign_key: true
      t.references :student, foreign_key: true
      t.references :admin, foreign_key: true
      t.string :caption
      t.string :latitude
      t.string :longitude
      t.string :watermark_text
      t.string :storage_key
      t.datetime :taken_at
      t.timestamps
    end

    create_table :voice_notes do |t|
      t.references :student, null: false, foreign_key: true
      t.references :course, foreign_key: true
      t.string :audio_key
      t.text :transcript
      t.json :structured, default: "{}"
      t.string :status, default: "pending" # pending | transcribed | structured | failed
      t.timestamps
    end

    create_table :push_deliveries do |t|
      t.references :student, null: false, foreign_key: true
      t.string :channel, null: false # sms | webpush | wechat_mp
      t.string :template_key
      t.string :title
      t.text :body
      t.string :status, default: "queued" # queued | sent | failed
      t.json :payload, default: "{}"
      t.datetime :sent_at
      t.timestamps
    end

    create_table :surveys do |t|
      t.string :title, null: false
      t.string :survey_type, null: false # pre_training | daily | post_exam
      t.references :course, foreign_key: true
      t.json :questions, default: "[]"
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    create_table :survey_responses do |t|
      t.references :survey, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.json :answers, default: "{}"
      t.integer :score
      t.timestamps
    end
    add_index :survey_responses, [ :survey_id, :student_id ], unique: true

    create_table :feedback_signals do |t|
      t.references :student, null: false, foreign_key: true
      t.string :matchable_type, null: false
      t.bigint :matchable_id, null: false
      t.string :signal_type, null: false # useful | not_useful | applied | completed
      t.string :weight, default: "1.0"
      t.timestamps
    end
    add_index :feedback_signals, [ :matchable_type, :matchable_id ]

    create_table :match_weights do |t|
      t.string :tag_category, null: false
      t.string :weight, default: "1.0", null: false
      t.timestamps
    end
    add_index :match_weights, :tag_category, unique: true

    create_table :resource_gaps do |t|
      t.references :district, foreign_key: true
      t.string :industry
      t.string :gap_type, null: false # policy | course | mentor
      t.string :title, null: false
      t.text :description
      t.integer :demand_count, default: 0
      t.integer :supply_count, default: 0
      t.string :severity, default: "medium" # low | medium | high | critical
      t.timestamps
    end

    create_table :alerts do |t|
      t.string :title, null: false
      t.text :body
      t.string :severity, default: "medium"
      t.string :status, default: "open" # open | acknowledged | closed
      t.references :district, foreign_key: true
      t.string :source_type
      t.bigint :source_id
      t.timestamps
    end

    create_table :attributions do |t|
      t.references :student, null: false, foreign_key: true
      t.string :outcome_type, null: false # income_up | honor | enrollment_complete
      t.string :matchable_type
      t.bigint :matchable_id
      t.string :contribution, default: "0"
      t.json :details, default: "{}"
      t.timestamps
    end

    create_table :showcase_cases do |t|
      t.references :student, null: false, foreign_key: true
      t.references :district, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.integer :contribution_score, default: 0, null: false
      t.boolean :published, default: false, null: false
      t.timestamps
    end

    create_table :knowledge_articles do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.string :category
      t.boolean :published, default: true, null: false
      t.timestamps
    end

    create_table :mentor_answers do |t|
      t.references :student, null: false, foreign_key: true
      t.references :mentor, foreign_key: true
      t.text :question, null: false
      t.text :answer_text
      t.string :audio_key
      t.string :status, default: "open" # open | answered
      t.timestamps
    end
  end
end
