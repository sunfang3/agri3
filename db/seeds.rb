# frozen_string_literal: true

# Dependency order for development, demos and explicitly selected test data.
# SEED_MULTIPLIER=1 loads the original small dataset; the default is eightfold.
ActiveRecord::Base.transaction do
  Oaken.seed :data, :districts, :resources,
    "cases/enrollments", "cases/profiles", "cases/learning",
    "cases/conversions", "cases/matching", :exports
end

puts "Seed complete: districts=#{District.jinan_active.count}, students=#{Student.count}, policies=#{Policy.count}, courses=#{Course.count}"
puts "Demo logins: city@jinan.local, admin@licheng.local, 13800000009 (password: password for new accounts)"
