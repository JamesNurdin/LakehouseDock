WITH promo_info AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_id,
    start_d.d_year AS start_year,
    start_d.d_date AS start_date,
    end_d.d_date AS end_date,
    date_diff('day', start_d.d_date, end_d.d_date) AS duration_days,
    p.p_cost,
    p.p_purpose,
    p.p_channel_details,
    p.p_channel_tv
  FROM promotion p
  JOIN date_dim start_d
    ON p.p_start_date_sk = start_d.d_date_sk
  JOIN date_dim end_d
    ON p.p_end_date_sk = end_d.d_date_sk
  WHERE start_d.d_current_quarter = 'Y'
    AND p.p_channel_tv = 'N'
    AND regexp_like(p.p_channel_details, '\\b[A-Z][a-z]+\\b')
    AND p.p_channel_details LIKE '%family%'
)
SELECT
  pi.start_year,
  COUNT(pi.p_promo_sk) AS promo_cnt,
  SUM(pi.p_cost) AS total_cost,
  AVG(pi.p_cost) AS avg_cost,
  SUM(pi.duration_days) AS total_duration,
  regexp_extract(pi.p_channel_details, '^([^,]+)', 1) AS first_clause,
  CONCAT('Year ', CAST(pi.start_year AS varchar), ': ', pi.p_purpose) AS year_purpose,
  (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_purpose = pi.p_purpose) AS purpose_avg_cost
FROM promo_info pi
GROUP BY
  pi.start_year,
  regexp_extract(pi.p_channel_details, '^([^,]+)', 1),
  CONCAT('Year ', CAST(pi.start_year AS varchar), ': ', pi.p_purpose),
  pi.p_purpose
HAVING COUNT(pi.p_promo_sk) > 3
ORDER BY total_cost DESC, promo_cnt DESC
LIMIT 100
