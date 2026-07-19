# frozen_string_literal: true

module AdminApp
  class ImportsController < AdminApp::BaseController
    def new
      render Views::AdminApp::Imports::New.new
    end

    def create
      file = params[:file]
      unless file
        redirect_to new_admin_import_path, alert: "请上传 Excel 文件"
        return
      end

      importer = Students::ExcelImporter.new(file.tempfile, filename: file.original_filename)
      result = if params[:commit_import].present?
        track_admin_action!("import_commit")
        importer.commit!
      else
        track_admin_action!("import_dry_run")
        importer.dry_run
      end
      render Views::AdminApp::Imports::New.new(result:)
    end
  end
end
