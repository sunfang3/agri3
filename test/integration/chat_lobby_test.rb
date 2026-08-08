# frozen_string_literal: true

require "test_helper"

class ChatLobbyTest < ActionDispatch::IntegrationTest
  test "guest must set nickname before seeing room" do
    get chat_path
    assert_response :success
    assert_select "[data-testid='nickname-gate']"
    assert_select "[data-testid='chat-room']", count: 0
  end

  test "guest sets nickname and sees empty lobby with cable subscription" do
    patch chat_identity_path, params: { chat_identity: { nickname: "访客甲" } }
    assert_redirected_to chat_path
    follow_redirect!
    assert_response :success
    assert_select "[data-testid='chat-room']"
    assert_select "[data-testid='current-identity']", text: /访客甲/
    assert_match(/turbo-cable-stream-source|signed-stream-name/, response.body)
    assert_match(/Litecable/, response.body)
  end

  test "logged-in student uses system name without gate" do
    district = District.create!(name: "聊区", code: "chat-#{SecureRandom.hex(3)}")
    student = Student.create!(
      phone: "135#{rand(10_000_000..99_999_999)}",
      name: "聊学员",
      district: district,
      password: "secret"
    )
    post student_login_path, params: { phone: student.phone, password: "secret" }
    get chat_path
    assert_response :success
    assert_select "[data-testid='chat-room']"
    assert_select "[data-testid='platform-identity']"
    assert_match(/聊学员/, response.body)
  end

  test "persisted history is shown after nickname" do
    ChatMessage.create!(room: "lobby", author: "历史君", body: "你好大厅")
    patch chat_identity_path, params: { chat_identity: { nickname: "后来者" } }
    follow_redirect!
    assert_select "[data-testid='message-body']", text: /你好大厅/
    assert_select "[data-testid='message-author']", text: /历史君/
  end

  test "home page links to chat" do
    get root_path
    assert_response :success
    assert_select "a[href='#{chat_path}']"
  end
end
