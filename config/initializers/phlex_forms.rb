# frozen_string_literal: true

PhlexForms.configure do |config|
  config.icon_renderer = PhlexForms::Configuration.glyphs_renderer
  config.field_variants = [:primary]
end
