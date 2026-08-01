(
SELECT
    p.p_promo_id AS promo_id,
    d.d_year AS promo_year,
    d.d_month_seq AS promo_month,
    p.p_cost AS promo_cost,
    CASE WHEN p.p_cost < 500 THEN 'LowCost' ELSE 'HighCost' END AS cost_category,
    p.p_response_target AS response_target,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY p.p_cost DESC) AS rank_val,
    COUNT(*) OVER (PARTITION BY d.d_year) AS promo_count_year
FROM promotion p
JOIN date_dim d
  ON p.p_start_date_sk = d.d_date_sk
WHERE p.p_channel_radio = 'N'
  AND p.p_channel_tv = 'N'
  AND p.p_response_target >= 1
  AND d.d_moy IN (1, 11)
  AND EXISTS (
      SELECT 1
      FROM date_dim d2
      WHERE d2.d_date_sk = p.p_end_date_sk
        AND d2.d_year = 2002
  )
)
UNION ALL
(
SELECT
    p.p_promo_id AS promo_id,
    d.d_year AS promo_year,
    d.d_month_seq AS promo_month,
    p.p_cost AS promo_cost,
    CASE WHEN p.p_cost < 500 THEN 'LowCost' ELSE 'HighCost' END AS cost_category,
    p.p_response_target AS response_target,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY p.p_response_target DESC) AS rank_val,
    COUNT(*) OVER (PARTITION BY d.d_year) AS promo_count_year
FROM promotion p
JOIN date_dim d
  ON p.p_start_date_sk = d.d_date_sk
WHERE p.p_channel_radio = 'N'
  AND p.p_channel_tv = 'N'
  AND p.p_response_target >= 5
  AND d.d_week_seq >= 3
  AND EXISTS (
      SELECT 1
      FROM date_dim d2
      WHERE d2.d_date_sk = p.p_end_date_sk
        AND d2.d_year = 2003
  )
)
LIMIT 100
