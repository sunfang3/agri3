# frozen_string_literal: true

class Views::AdminApp::Imports::New < Views::Base
  def initialize(result: nil)
    @result = result
  end

  def view_template
    div(class: "mx-auto max-w-2xl px-4 py-8 space-y-4") do
      h1(class: "text-xl font-bold") { "历史学员 Excel 导入" }
      p(class: "text-sm opacity-70") do
        "列：phone, name, district_code, primary_industry, scale, annual_income, honors。先 dry-run 预览再 commit。"
      end

      Form(url: admin_imports_path, method: :post, scope: false, class: "flex flex-col gap-3") do
        input(type: "file", name: "file", accept: ".xlsx,.xls,.csv", class: "file-input file-input-bordered", required: true)
        div(class: "flex gap-2") do
          button(name: "dry_run", value: "1", class: "btn btn-outline", type: "submit") { "Dry-run 预览" }
          button(name: "commit_import", value: "1", class: "btn btn-primary", type: "submit") { "确认导入" }
        end
      end

      if @result
        div(class: "alert #{@result[:dry_run] ? "alert-info" : "alert-success"}") do
          plain "#{@result[:dry_run] ? "Dry-run" : "已提交"}: "
          plain "total=#{@result[:total]} valid=#{@result[:valid]} invalid=#{@result[:invalid]} "
          plain "created=#{@result[:created]} updated=#{@result[:updated]}"
        end
        div(class: "overflow-x-auto") do
          table(class: "table table-xs") do
            thead { tr { %w[行 动作 错误 attrs].each { |h| th { h } } } }
            tbody do
              @result[:rows].each do |r|
                tr do
                  td { r.row_number.to_s }
                  td { r.action.to_s }
                  td(class: "text-error") { r.errors.join("; ") }
                  td(class: "text-xs") { r.attrs.inspect }
                end
              end
            end
          end
        end
      end

      a(href: admin_root_path, class: "btn btn-ghost") { "返回后台" }
    end
  end
end
