# frozen_string_literal: true

class ProcessVoiceNoteJob < ApplicationJob
  queue_as :default

  def perform(voice_note_id)
    note = VoiceNote.find(voice_note_id)
    VoiceNotes::Pipeline.new.process!(note)
  end
end
