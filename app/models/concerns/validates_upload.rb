module ValidatesUpload
  extend ActiveSupport::Concern

  class_methods do
    def validates_upload(name, types:, maximum:)
      validate do
        upload = public_send(name)
        next unless upload.attached?

        errors.add(name, "文件类型不支持") unless upload.content_type.in?(types)
        errors.add(name, "文件过大") if upload.byte_size > maximum
      end
    end
  end
end
