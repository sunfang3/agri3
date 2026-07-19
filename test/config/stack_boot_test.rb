# frozen_string_literal: true

require "test_helper"

class StackBootTest < ActiveSupport::TestCase
  test "application boots as Agri3 on Litedb without pg or pgbus" do
    assert_equal "Agri3", Rails.application.class.module_parent_name
    assert_equal "litedb", ActiveRecord::Base.connection.adapter_name.downcase
    assert_nil defined?(Pgbus)
    refute Gem.loaded_specs.key?("pg")
    refute Gem.loaded_specs.key?("pgbus")
    refute Gem.loaded_specs.key?("solid_cache")
    refute Gem.loaded_specs.key?("solid_cable")
  end

  test "product gems are available" do
    assert defined?(Avo)
    assert defined?(BCrypt)
    assert defined?(Roo)
    assert defined?(Axlsx)
  end
end
