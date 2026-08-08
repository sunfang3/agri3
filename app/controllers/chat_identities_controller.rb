# frozen_string_literal: true

class ChatIdentitiesController < ApplicationController
  include ChatNicknameResolvable

  def update
    if platform_chat_display_name.present?
      resolve_chat_nickname!
      return redirect_to chat_path
    end

    return redirect_to chat_path if session[:chat_nickname].present?

    identity = ChatIdentity.new(identity_params)

    if identity.valid?
      session[:chat_nickname] = identity.nickname
      session[:chat_nickname_source] = "guest"
      redirect_to chat_path
    else
      render Views::Chat::Lobby.new(identity:, locked: false), status: :unprocessable_entity
    end
  end

  private

  def identity_params
    params.expect(chat_identity: [ :nickname ])
  end
end
