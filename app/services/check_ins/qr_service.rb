# frozen_string_literal: true

module CheckIns
  class QrService
    EARTH_RADIUS_M = 6_371_000
    DEFAULT_RADIUS_M = 500

    def generate_token(course, expires_in: 1.hour)
      payload = { course_id: course.id, exp: expires_in.from_now.to_i }
      Base64.urlsafe_encode64(payload.to_json)
    end

    def check_in!(student:, course:, token:, latitude:, longitude:, radius_m: DEFAULT_RADIUS_M)
      verify_token!(token, course)
      enrollment = Enrollment.find_by!(student: student, course: course)
      raise ArgumentError, "must be enrolled" unless enrollment.status.in?(%w[enrolled completed])

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
      data = JSON.parse(Base64.urlsafe_decode64(token))
      raise ArgumentError, "token course mismatch" unless data["course_id"].to_i == course.id
      raise ArgumentError, "token expired" if data["exp"].to_i < Time.current.to_i
    end

    def to_rad(deg)
      deg * Math::PI / 180.0
    end
  end
end
