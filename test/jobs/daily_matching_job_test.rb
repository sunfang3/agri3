# frozen_string_literal: true

require "test_helper"

class DailyMatchingJobTest < ActiveJob::TestCase
  setup do
    @district = District.create!(name: "Job区", code: "job-#{SecureRandom.hex(3)}")
    @student = Student.create!(
      phone: "132#{rand(10_000_000..99_999_999)}",
      name: "Job",
      district: @district,
      password: "secret"
    )
    @tag = Tag.create!(name: "job-tag-#{SecureRandom.hex(2)}", category: "industry")
    @student.tags = [ @tag ]
    @policy = Policy.create!(title: "Job政策", published: true)
    @policy.tags = [ @tag ]
  end

  test "job runs matching for students with no args" do
    DailyMatchingJob.perform_now
    assert ResourceMatch.exists?(student: @student, matchable: @policy)
  end

  test "positional engine arg from recurring.yml style does not raise" do
    # Mirrors config/recurring.yml args: ["rules"] → perform("rules")
    assert_nothing_raised do
      DailyMatchingJob.perform_now("rules")
    end
    match = ResourceMatch.find_by!(student: @student, matchable: @policy)
    assert_equal "rules", match.engine
  end

  test "keyword engine arg still works" do
    DailyMatchingJob.perform_now(engine: "rules")
    assert ResourceMatch.exists?(student: @student, matchable: @policy, engine: "rules")
  end

  test "perform_later enqueues on Active Job with positional rules arg" do
    # Production cron/timer: DailyMatchingJob.perform_later("rules")
    assert_enqueued_with(job: DailyMatchingJob, args: [ "rules" ]) do
      DailyMatchingJob.perform_later("rules")
    end
  end

  test "cosine engine path via positional arg" do
    DailyMatchingJob.perform_now("cosine")
    match = ResourceMatch.find_by!(student: @student, matchable: @policy)
    assert_equal "cosine", match.engine
  end
end
