WITH open_sites AS (
  SELECT
    ws.web_site_sk,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    od.d_date AS open_date,
    ws.web_gmt_offset,
    (
      SELECT COUNT(*)
      FROM web_site ws2
      WHERE ws2.web_city = ws.web_city
    ) AS city_site_count,
    LAG(od.d_date) OVER (PARTITION BY ws.web_state ORDER BY od.d_date) AS prev_open_date
  FROM web_site ws
  JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
  WHERE ws.web_open_date_sk IN (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2000
  )
    AND ws.web_gmt_offset > (
      SELECT MAX(web_gmt_offset)
      FROM web_site
      WHERE web_country = 'USA'
    )
),
close_sites AS (
  SELECT
    ws.web_site_sk,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    cd.d_date AS close_date,
    ws.web_gmt_offset,
    (
      SELECT COUNT(*)
      FROM web_site ws2
      WHERE ws2.web_city = ws.web_city
    ) AS city_site_count,
    LAG(cd.d_date) OVER (PARTITION BY ws.web_state ORDER BY cd.d_date) AS prev_close_date
  FROM web_site ws
  JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
  WHERE ws.web_close_date_sk IN (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
  )
    AND ws.web_gmt_offset > (
      SELECT MAX(web_gmt_offset)
      FROM web_site
      WHERE web_country = 'USA'
    )
)
SELECT
  web_site_sk,
  web_name,
  web_city,
  web_state,
  open_date AS event_date,
  'open' AS event_type,
  city_site_count,
  prev_open_date AS prior_event_date
FROM open_sites
UNION ALL
SELECT
  web_site_sk,
  web_name,
  web_city,
  web_state,
  close_date AS event_date,
  'close' AS event_type,
  city_site_count,
  prev_close_date AS prior_event_date
FROM close_sites
ORDER BY web_state, event_date DESC
LIMIT 100
