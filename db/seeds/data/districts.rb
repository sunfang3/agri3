# frozen_string_literal: true

demo_multiplier
District::JINAN_DISTRICTS.each do |meta|
  districts.create meta[:code].to_sym, unique_by: :code,
    code: meta[:code], name: meta[:name], active: true
end
