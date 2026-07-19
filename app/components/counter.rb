# frozen_string_literal: true

class Components::Counter < Components::Base
  include Phlex::Reactive::Component

  skip_verify_authorized

  reactive_state :count
  action :increment
  action :decrement
  action :reset

  def initialize(count: 0)
    @count = count
  end

  def id = "counter"

  def increment = @count += 1
  def decrement = @count -= 1
  def reset = @count = 0

  def view_template
    div(**reactive_root(class: "flex items-center gap-3")) do
      button(**mix(on(:decrement), class: "btn btn-sm")) { "-" }
      span(class: "min-w-10 text-center text-2xl tabular-nums") { @count.to_s }
      button(**mix(on(:increment), class: "btn btn-sm btn-primary")) { "+" }
      button(**mix(on(:reset), class: "btn btn-sm btn-ghost")) { "重设" }
    end
  end
end
