def media_layout:
  (.logical.width // 0 | if type == "number" and . > 0 and . <= 100000 then floor else 0 end) as $width
  | (if $width > 1700 then ([100, (([$width * 0.30, $width - 1500] | min) / 10 | floor)] | min) else 0 end) as $cells
  | (if $cells >= 70 then
       (($cells - 6) * 0.50 | floor) as $title | (($cells - 6) * 0.28 | floor) as $artist
       | [$title, $artist, $cells - 6 - $title - $artist]
     elif $cells >= 40 then (($cells - 3) * 0.65 | floor) as $title | [$title, $cells - 3 - $title, 0]
     elif $cells >= 18 then [$cells, 0, 0] else [0, 0, 0] end) as $fields
  | ("{status_icon}" + if $fields[0] > 0 then " {dynamic}" else "" end) as $format
  | {logical_width: $width, config: {
      format: $format, "format-playing": $format, "format-paused": $format, "format-stopped": $format,
      "title-len": $fields[0], "artist-len": $fields[1], "album-len": $fields[2],
      "dynamic-len": (if $fields[0] > 0 then $cells else 0 end),
      "max-length": (if $fields[0] > 0 then $cells + 2 else 2 end)}};
