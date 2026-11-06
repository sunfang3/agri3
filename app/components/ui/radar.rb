class Components::Ui::Radar < Phlex::SVG
  def initialize(scores:)
    @scores = scores
  end

  def view_template
    svg(viewbox: "0 0 320 280", role: "img", aria_label: "六维能力雷达图", class: "radar-chart") do
      [ 20, 40, 60, 80, 100 ].each { |level| polygon(points: points(Array.new(6, level)), fill: "none", stroke: "rgba(167,155,255,.18)") }
      6.times do |i|
        x, y = point(i, 100)
        line(x1: 160, y1: 140, x2: x, y2: y, stroke: "rgba(167,155,255,.2)")
      end
      polygon(points: points(CapabilityAssessment::DIMENSIONS.keys.map { |key| @scores.fetch(key, 0) }), fill: "rgba(107,91,242,.32)", stroke: "#a79bff", stroke_width: 2)
      CapabilityAssessment::DIMENSIONS.each_with_index do |(key, label), i|
        x, y = point(i, 125)
        text(x: x, y: y, fill: "#a49dd4", font_size: 11, text_anchor: "middle", dominant_baseline: "middle") { "#{label} #{@scores[key]}" }
      end
    end
  end

  private

  def point(index, value)
    angle = index * Math::PI / 3 - Math::PI / 2
    [ (160 + Math.cos(angle) * value).round(2), (140 + Math.sin(angle) * value).round(2) ]
  end

  def points(values)
    values.each_with_index.map { |value, index| point(index, value.to_f).join(",") }.join(" ")
  end
end
