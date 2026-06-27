WITH parsed_logs AS (
  SELECT
    line,
    regexp_extract(line, '^([^ ]+)', 1) AS ip,
    regexp_extract(line, '\\[(.*?)\\]', 1) AS datetime_str,
    regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 1) AS request_method,
    regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 2) AS request_path,
    regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 3) AS http_version,
    regexp_extract(line, '"[^\"]+" (\\d{3})', 1) AS status_code
  FROM web_logs
)
SELECT
  request_method,
  status_code,
  COUNT(*) AS request_cnt,
  COUNT(DISTINCT ip) AS unique_ip_cnt,
  AVG(length(line)) AS avg_line_len,
  MIN(datetime_str) AS earliest_log,
  MAX(datetime_str) AS latest_log
FROM parsed_logs
WHERE request_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY request_method, status_code
ORDER BY request_cnt DESC
LIMIT 20
