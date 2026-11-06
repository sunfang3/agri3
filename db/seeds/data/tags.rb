# frozen_string_literal: true

TAG_SPECS.each do |label, category, name, value|
  tags.create label, unique_by: [ :category, :name ], category: category, name: name, value: value
end
