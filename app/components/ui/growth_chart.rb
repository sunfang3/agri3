class Components::Ui::GrowthChart < Phlex::SVG
  def initialize(values:)
    @values = values.to_a
  end

  def view_template
    svg(viewbox: "0 0 560 220", role: "img", aria_label: "能力成长曲线", class: "growth-chart") do
      [ 0, 25, 50, 75, 100 ].each do |level|
        y = 180 - level * 1.5
        line(x1: 38, y1: y, x2: 535, y2: y, stroke: "rgba(167,155,255,.13)")
        text(x: 25, y: y + 4, fill: "#6d669d", font_size: 10, text_anchor: "end") { level.to_s }
      end
      coords = @values.each_with_index.map { |(_, value), i| [ 50 + i * (470.0 / [ @values.size - 1, 1 ].max), 180 - value.to_f * 1.5 ] }
      polyline(points: coords.map { |c| c.join(",") }.join(" "), stroke: "#a79bff", stroke_width: 2, fill: "none")
      coords.each_with_index do |(x, y), i|
        circle(cx: x, cy: y, r: 4, fill: "#edb81c")
        text(x: x, y: y - 12, fill: "#edb81c", font_size: 11, text_anchor: "middle") { @values[i][1].to_s }
        if i.zero? || i == coords.size - 1 || coords.size < 6
          text(x: x, y: 204, fill: "#a49dd4", font_size: 10, text_anchor: "middle") { @values[i][0].to_s }
        end
      end
    end
  end
end
