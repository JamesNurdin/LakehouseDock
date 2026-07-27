WITH base AS (
  SELECT
    cs.cs_net_paid,
    d.d_day_name,
    d.d_fy_week_seq,
    d.d_date_id,
    t.t_hour,
    t.t_time_id,
    CONCAT(d.d_day_name, '_', CAST(t.t_hour AS varchar)) AS day_hour_key
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE regexp_like(d.d_date_id, '^AAAA.*A$')
    AND t.t_time_id LIKE '%A%'
    AND EXISTS (
      SELECT 1 FROM catalog_sales cs2
      WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
        AND cs2.cs_net_paid > 10000
    )
)
SELECT
  day_name,
  hour,
  day_hour_key,
  total_net_paid,
  avg_net_paid,
  overall_avg,
  CASE WHEN max_net_paid > 10000 THEN 'High' ELSE 'Normal' END AS category
FROM (
  SELECT
    d_day_name AS day_name,
    t_hour AS hour,
    day_hour_key,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_net_paid) AS avg_net_paid,
    MAX(cs_net_paid) AS max_net_paid,
    (SELECT AVG(cs_net_paid) FROM catalog_sales) AS overall_avg
  FROM base
  WHERE d_fy_week_seq <= 10
    AND regexp_extract(d_date_id, '(....)', 1) = 'AAAA'
  GROUP BY d_day_name, t_hour, day_hour_key

  UNION ALL

  SELECT
    d_day_name AS day_name,
    t_hour AS hour,
    day_hour_key,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_net_paid) AS avg_net_paid,
    MAX(cs_net_paid) AS max_net_paid,
    (SELECT AVG(cs_net_paid) FROM catalog_sales) AS overall_avg
  FROM base
  WHERE d_fy_week_seq > 10
    AND regexp_extract(d_date_id, '(....)', 1) = 'AAAA'
  GROUP BY d_day_name, t_hour, day_hour_key
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
