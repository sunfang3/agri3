# frozen_string_literal: true

# Resolve lobby author for /chat:
# - session[:chat_nickname] for guests
# - optional prefill from Student / Admin login sessions
module ChatNicknameResolvable
  extend ActiveSupport::Concern

  private

  def resolve_chat_nickname!
    return session[:chat_nickname] if session[:chat_nickname].present?

    if (name = platform_chat_display_name).present?
      session[:chat_nickname] = name.to_s.strip[0, 20]
      session[:chat_nickname_source] = "platform"
    end
    session[:chat_nickname]
  end

  def platform_chat_nickname?
    session[:chat_nickname_source] == "platform"
  end

  def platform_chat_display_name
    if session[:student_id].present?
      Student.find_by(id: session[:student_id])&.name
    elsif session[:admin_id].present?
      Admin.find_by(id: session[:admin_id])&.name
    end
  end
end
