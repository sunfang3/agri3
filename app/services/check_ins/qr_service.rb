# frozen_string_literal: true

module CheckIns
  class QrService
    EARTH_RADIUS_M = 6_371_000
    DEFAULT_RADIUS_M = 500

    def generate_token(course, expires_in: 1.hour)
      verifier.generate(course.id, expires_in: expires_in, purpose: :course_check_in)
    end

    def check_in!(student:, course:, token:, latitude:, longitude:, radius_m: DEFAULT_RADIUS_M)
      verify_token!(token, course)
      enrollment = Enrollment.find_by!(student: student, course: course)
      raise ArgumentError, "请先完成课程录取" unless enrollment.status.in?(%w[enrolled completed])

      lat = Float(latitude, exception: false)
      lng = Float(longitude, exception: false)
      raise ArgumentError, "请提供有效的经纬度" unless lat&.between?(-90, 90) && lng&.between?(-180, 180)

      distance = haversine_m(
        latitude.to_f, longitude.to_f,
        course.latitude.to_f, course.longitude.to_f
      )
      gps_valid = course.latitude.present? && course.longitude.present? && distance <= radius_m

      CheckIn.create!(
        enrollment: enrollment,
        student: student,
        course: course,
        token: token,
        latitude: latitude,
        longitude: longitude,
        gps_valid: gps_valid,
        distance_meters: distance.round(2),
        checked_in_at: Time.current
      )
    end

    def haversine_m(lat1, lon1, lat2, lon2)
      dlat = to_rad(lat2 - lat1)
      dlon = to_rad(lon2 - lon1)
      a = Math.sin(dlat / 2)**2 + Math.cos(to_rad(lat1)) * Math.cos(to_rad(lat2)) * Math.sin(dlon / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      EARTH_RADIUS_M * c
    end

    private

    def verify_token!(token, course)
      course_id = verifier.verified(token, purpose: :course_check_in)
      raise ArgumentError, "签到码无效或已过期" unless course_id == course.id
    end

    def verifier
      Rails.application.message_verifier("course_check_in")
    end

    def to_rad(deg)
      deg * Math::PI / 180.0
    end
  end
end
