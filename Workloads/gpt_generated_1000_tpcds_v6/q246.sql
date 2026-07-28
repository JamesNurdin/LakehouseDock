WITH open_events AS (
  SELECT
    ws.web_site_id,
    dd.d_year AS event_year,
    'open' AS event_type,
    ws.web_name,
    ws.web_zip,
    regexp_extract(ws.web_zip, '(\\d{3})', 1) AS zip_prefix,
    ws.web_city,
    ws.web_county
  FROM web_site ws
  JOIN date_dim dd ON ws.web_open_date_sk = dd.d_date_sk
  WHERE ws.web_name LIKE '%Shop%'
    AND regexp_like(ws.web_county, 'County$')
    AND dd.d_year BETWEEN 2000 AND 2020
),
close_events AS (
  SELECT
    ws.web_site_id,
    dd.d_year AS event_year,
    'close' AS event_type,
    ws.web_name,
    ws.web_zip,
    regexp_extract(ws.web_zip, '(\\d{3})', 1) AS zip_prefix,
    ws.web_city,
    ws.web_county
  FROM web_site ws
  JOIN date_dim dd ON ws.web_close_date_sk = dd.d_date_sk
  WHERE ws.web_name LIKE '%Shop%'
    AND regexp_like(ws.web_county, 'County$')
    AND dd.d_year BETWEEN 2000 AND 2020
),
combined AS (
  SELECT * FROM open_events
  UNION ALL
  SELECT * FROM close_events
),
aggregated AS (
  SELECT
    event_year,
    event_type,
    zip_prefix,
    COUNT(DISTINCT web_site_id) AS site_count
  FROM combined
  GROUP BY GROUPING SETS (
    (event_year, event_type, zip_prefix),
    (event_year, event_type),
    (event_type)
  )
)
SELECT
  event_year,
  event_type,
  zip_prefix,
  CONCAT('ZIP-', zip_prefix) AS zip_label,
  site_count,
  SUM(site_count) OVER (PARTITION BY event_type ORDER BY event_year ROWS UNBOUNDED PRECEDING) AS cumulative_sites
FROM aggregated
WHERE site_count > 0
ORDER BY event_year, event_type, zip_prefix
LIMIT 100
