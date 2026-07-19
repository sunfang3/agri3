# frozen_string_literal: true

require "test_helper"

class Matching::CosineEngineTest < ActiveSupport::TestCase
  test "pure cosine similarity of identical vectors is 1" do
    a = { "industry" => 1.0, "scale_norm" => 0.5 }
    assert_in_delta 1.0, Matching::CosineEngine.cosine_similarity(a, a), 0.0001
  end

  test "orthogonal vectors have zero similarity" do
    a = { "industry" => 1.0, "course" => 0.0 }
    b = { "industry" => 0.0, "course" => 1.0 }
    assert_in_delta 0.0, Matching::CosineEngine.cosine_similarity(a, b), 0.0001
  end

  test "score maps non-positive similarity and empty tags to 0 not 50" do
    assert_equal 0, Matching::CosineEngine.score_from_similarity(0.0)
    assert_equal 0, Matching::CosineEngine.score_from_similarity(-0.5)
    assert_equal 0, Matching::CosineEngine.score_from_similarity(0.5, resource_tag_count: 0)
    assert_equal 100, Matching::CosineEngine.score_from_similarity(1.0)
    assert_equal 50, Matching::CosineEngine.score_from_similarity(0.5)
  end

  test "untagged resource scores 0 via engine" do
    district = District.create!(name: "正交区", code: "test-orth-#{SecureRandom.hex(3)}")
    student = Student.create!(
      phone: "136#{rand(10_000_000..99_999_999)}",
      name: "余弦空",
      district: district,
      scale: 100,
      annual_income: 200_000,
      password: "secret"
    )
    tag = Tag.create!(name: "粮油-#{SecureRandom.hex(2)}", category: "industry")
    student.tags = [ tag ]
    empty_policy = Policy.create!(title: "无标签政策", published: true)
    engine = Matching::CosineEngine.new(student)
    assert_equal 0, engine.score_for(empty_policy)
  end

  test "realtime match writes cosine engine rows" do
    district = District.create!(name: "槐荫", code: "test-hy-#{SecureRandom.hex(3)}")
    student = Student.create!(
      phone: "136#{rand(10_000_000..99_999_999)}",
      name: "余弦",
      district: district,
      scale: 100,
      annual_income: 200_000,
      password: "secret"
    )
    tag = Tag.create!(name: "蔬菜-#{SecureRandom.hex(2)}", category: "industry")
    student.tags = [ tag ]
    policy = Policy.create!(title: "蔬菜政策", published: true)
    policy.tags = [ tag ]

    match = Matching::Runner.new(student, engine: :cosine).match_one(policy)
    assert_equal "cosine", match.engine
    assert_operator match.score, :>, 0
    assert match.cosine_similarity.present?
  end
end
