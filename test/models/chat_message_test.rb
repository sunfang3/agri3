# frozen_string_literal: true

require "test_helper"

class ChatMessageTest < ActiveSupport::TestCase
  test "normalizes and validates author and body" do
    m = ChatMessage.new(room: "lobby", author: "  ab  ", body: "  hi  ")
    assert m.valid?
    assert_equal "ab", m.author
    assert_equal "hi", m.body
  end

  test "rejects blank or oversized body" do
    assert_not ChatMessage.new(room: "lobby", author: "alice", body: "").valid?
    assert_not ChatMessage.new(room: "lobby", author: "a", body: "x").valid?
    assert_not ChatMessage.new(room: "lobby", author: "alice", body: "x" * 501).valid?
  end

  test "recent_for returns chronological latest limit" do
    room = "lobby-test-#{SecureRandom.hex(3)}"
    3.times { |i| ChatMessage.create!(room:, author: "user#{i}x", body: "msg#{i}") }
    recent = ChatMessage.recent_for(room, limit: 2)
    assert_equal 2, recent.size
    assert_equal "msg1", recent.first.body
    assert_equal "msg2", recent.last.body
  end

  test "stream_key is chat plus room" do
    assert_equal [ "chat", "lobby" ], ChatMessage.stream_key("lobby")
  end
end
