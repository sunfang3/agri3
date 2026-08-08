# frozen_string_literal: true

class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.string :room, null: false, default: "lobby"
      t.string :author, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :chat_messages, [ :room, :created_at, :id ], name: "index_chat_messages_on_room_and_created_at_and_id"
  end
end
