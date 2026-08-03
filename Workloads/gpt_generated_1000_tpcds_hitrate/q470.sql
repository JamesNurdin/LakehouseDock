WITH site_dates AS (
  SELECT
    ws.web_site_sk,
    ws.web_name,
    ws.web_state,
    ws.web_country,
    ws.web_gmt_offset,
    ws.web_tax_percentage,
    dd.d_date,
    dd.d_year,
    dd.d_holiday,
    ARRAY[ws.web_state, ws.web_country] AS location_array
  FROM web_site ws
  JOIN date_dim dd
    ON ws.web_open_date_sk = dd.d_date_sk
  WHERE ws.web_gmt_offset > 0
    AND ws.web_tax_percentage BETWEEN 0.05 AND 0.15
    AND dd.d_year = 2000
    AND dd.d_holiday = 'N'
),

expanded AS (
  SELECT
    sd.*,
    loc AS location
  FROM site_dates sd
  CROSS JOIN UNNEST(sd.location_array) AS t(loc)
),

filtered AS (
  SELECT
    e.web_site_sk,
    e.web_name,
    e.web_state,
    e.web_country,
    e.location,
    e.d_year,
    e.d_date,
    e.web_gmt_offset,
    e.web_tax_percentage
  FROM expanded e
  WHERE e.location LIKE 'U%'
    AND e.web_name IS NOT NULL
),

agg AS (
  SELECT
    f.web_state,
    f.web_country,
    COUNT(*) AS site_count,
    SUM(f.web_tax_percentage) AS total_tax,
    AVG(f.web_gmt_offset) AS avg_gmt_offset,
    MIN(f.d_date) AS first_open_date,
    MAX(f.d_date) AS last_open_date
  FROM filtered f
  GROUP BY f.web_state, f.web_country
  HAVING COUNT(*) >= 2
),

max_date_sub AS (
  SELECT MAX(d_date) AS max_date FROM date_dim
),

final AS (
  SELECT
    a.web_state,
    a.web_country,
    a.site_count,
    a.total_tax,
    a.avg_gmt_offset,
    a.first_open_date,
    a.last_open_date,
    (SELECT max_date FROM max_date_sub) AS overall_max_date
  FROM agg a
  WHERE a.avg_gmt_offset > (
    SELECT AVG(web_gmt_offset) FROM web_site WHERE web_gmt_offset > 0
  )
)
SELECT *
FROM (
  SELECT * FROM final
  EXCEPT
  SELECT * FROM (
    SELECT * FROM final WHERE site_count = 0
  )
) t
ORDER BY site_count DESC, total_tax ASC
LIMIT 100
