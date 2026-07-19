# frozen_string_literal: true

module Components::Broadcasting
  STREAM = :application

  private

  def broadcast_replace_to_peers(*components)
    components.each do |component|
      component.class.broadcast_to(STREAM, replace: component, morph: true, exclude: reactive_connection_id)
    end
  end
end
