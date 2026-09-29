module IconHelper
  # Renderiza iconos SVG en línea, consistentes, accesibles y estilizados con CSS
  def dashboard_icon(name, classes: "")
    case name.to_sym
    when :calendar
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.rect(width: "18", height: "18", x: "3", y: "4", rx: "2") +
          tag.line(x1: "16", x2: "16", y1: "2", y2: "6") +
          tag.line(x1: "8", x2: "8", y1: "2", y2: "6") +
          tag.line(x1: "3", x2: "21", y1: "10", y2: "10")
      end
    when :court, :stadium
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.rect(width: "20", height: "14", x: "2", y: "5", rx: "2") +
          tag.line(x1: "12", x2: "12", y1: "5", y2: "19") +
          tag.circle(cx: "12", cy: "12", r: "3")
      end
    when :clock, :time
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.circle(cx: "12", cy: "12", r: "10") +
          tag.polyline(points: "12 6 12 12 16 14")
      end
    when :cancelled, :alert_circle
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.circle(cx: "12", cy: "12", r: "10") +
          tag.line(x1: "15", x2: "9", y1: "9", y2: "15") +
          tag.line(x1: "9", x2: "15", y1: "9", y2: "15")
      end
    when :live, :activity
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.path(d: "M22 12h-4l-3 9L9 3l-3 9H2")
      end
    when :next_shift, :fast_forward
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.polygon(points: "5 4 15 12 5 20 5 4") +
          tag.line(x1: "19", x2: "19", y1: "5", y2: "19")
      end
    when :building, :complex
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.rect(width: "16", height: "20", x: "4", y: "2", rx: "2") +
          tag.path(d: "M9 22v-4h6v4") +
          tag.path(d: "M8 6h.01M16 6h.01M8 10h.01M16 10h.01M8 14h.01M16 14h.01")
      end
    when :phone
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.path(d: "M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z")
      end
    when :check
      content_tag(:svg, class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", "aria-hidden": "true") do
        tag.polyline(points: "20 6 9 17 4 12")
      end
    else
      ""
    end
  end
end
