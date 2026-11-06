class AddUiWorkflows < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :capacity, :integer
    add_column :policies, :document_number, :string
    add_column :policies, :issuing_authority, :string
    create_table :student_needs do |t|
      t.references :student, null: false, foreign_key: true
      t.string :body, null: false
      t.string :status, null: false, default: "pending"
      t.text :response
      t.timestamps
    end
    create_table :honors do |t|
      t.references :student, null: false, foreign_key: true
      t.string :title, null: false
      t.date :awarded_on
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    create_table :policy_interactions do |t|
      t.references :student, null: false, foreign_key: true
      t.references :policy, null: false, foreign_key: true
      t.boolean :saved, null: false, default: false
      t.datetime :viewed_at
      t.string :application_status, null: false, default: "none"
      t.timestamps
      t.index [ :student_id, :policy_id ], unique: true
    end
    create_table :capability_assessments do |t|
      t.references :student, null: false, foreign_key: true
      t.date :assessed_on, null: false
      t.json :scores, null: false, default: "{}"
      t.timestamps
    end
    # Attachments back existing photo/PDF declarations as well as new evidence.
    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index :key, unique: true
    end
    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime :created_at, null: false
      t.index [ :record_type, :record_id, :name, :blob_id ], unique: true, name: "index_active_storage_attachments_uniqueness"
    end
    create_table :active_storage_variant_records do |t|
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.string :variation_digest, null: false
      t.index [ :blob_id, :variation_digest ], unique: true, name: "index_active_storage_variant_records_uniqueness"
    end
  end
end
