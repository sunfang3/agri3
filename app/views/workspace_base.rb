class Views::WorkspaceBase < Views::Base
  def url_for(record) = view_context.url_for(record)
  def heading(title, subtitle = nil)
    div(class: "page-heading") do
      div do
        p(class: "eyebrow") { "QILU AGRI · 济南市农广校" }
        h1 { title }
        p(class: "muted") { subtitle } if subtitle
      end
      yield if block_given?
    end
  end

  def panel(title, subtitle: nil, **attrs)
    section(class: "card", **attrs) do
      div(class: "card-h") do
        i(class: "bar")
        h2 { title }
        span(class: "sub") { subtitle } if subtitle
      end
      div(class: "card-b") { yield }
    end
  end

  def kpis(values)
    div(class: "g4 kpis") do
      values.each_with_index do |(label, value), index|
        div(class: "kpi #{%w[gold green cyan violet][index % 4]}") do
          div(class: "k-lbl") { label }
          div(class: "k-val") { value.nil? ? "—" : value.to_s }
          div(class: "k-foot") { "以实际记录统计" }
        end
      end
    end
  end

  def chip(text, tone = "")
    span(class: "tag #{tone}") { text.to_s }
  end

  def empty(text = "暂无记录，完成相关操作后将在这里展示")
    p(class: "empty-state") { text }
  end

  def action(label, url, primary: false)
    a(href: url, class: "tbtn #{'pri' if primary}") { label }
  end

  def bar_chart(values, max: nil)
    max ||= values.values.map(&:to_f).max.to_f
    div(class: "bar-chart") do
      values.each do |label, count|
        div(class: "bar-row") do
          span { label }
          div(class: "bar-t") { div(class: "bar-f", style: "width:#{max.positive? ? (count.to_f / max * 100).clamp(0, 100) : 0}%") }
          b { count.to_s }
        end
      end
    end
  end

  def data_table(headers)
    div(class: "tbl-wrap") do
      table(class: "tbl") do
        thead { tr { headers.each { |title| th { title } } } }
        tbody { yield }
      end
    end
  end

  def list_row(title, detail = nil)
    div(class: "record-row") do
      div do
        strong { title.to_s }
        p(class: "muted") { detail.to_s } if detail
      end
      yield if block_given?
    end
  end

  def date_label(value)
    value.present? ? value.to_s.first(10) : "—"
  end

  def text_field(name, label_text, value: nil, type: "text", **attrs)
    label(class: "form-label") do
      span { label_text }
      input(name: name, type: type, value: value, class: "field", **attrs)
    end
  end
end
