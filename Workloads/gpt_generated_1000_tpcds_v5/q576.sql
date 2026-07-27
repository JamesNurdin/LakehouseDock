WITH sales_a AS (
  SELECT
    sm.sm_type,
    p.p_promo_id,
    CONCAT(p.p_promo_id, '-', sm.sm_ship_mode_id) AS promo_ship_key,
    SUM(cs.cs_net_paid) AS total_paid,
    REGEXP_EXTRACT(p.p_channel_details, '^([^ ]+)') AS first_word_detail
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE p.p_channel_email = 'Y'
    AND REGEXP_LIKE(p.p_channel_details, '.*[Ff]eatures?.*')
    AND sm.sm_code LIKE 'AIR%'
  GROUP BY
    sm.sm_type,
    p.p_promo_id,
    sm.sm_ship_mode_id,
    REGEXP_EXTRACT(p.p_channel_details, '^([^ ]+)')
  HAVING SUM(cs.cs_net_paid) > 10000
),
sales_b AS (
  SELECT
    sm.sm_type,
    p.p_promo_id,
    CONCAT(p.p_promo_id, '-', sm.sm_ship_mode_id) AS promo_ship_key,
    SUM(cs.cs_net_paid) AS total_paid,
    REGEXP_EXTRACT(p.p_channel_details, '^([^ ]+)') AS first_word_detail
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE p.p_channel_email = 'N'
    AND p.p_channel_demo = 'N'
    AND sm.sm_code LIKE 'SEA%'
    AND REGEXP_LIKE(p.p_channel_details, '.*[Ee]xternal.*')
  GROUP BY
    sm.sm_type,
    p.p_promo_id,
    sm.sm_ship_mode_id,
    REGEXP_EXTRACT(p.p_channel_details, '^([^ ]+)')
  HAVING SUM(cs.cs_net_paid) > 5000
)
SELECT
  sm_type,
  COUNT(DISTINCT promo_ship_key) AS promo_ship_count,
  SUM(total_paid) AS aggregate_paid,
  MAX(first_word_detail) AS sample_detail
FROM (
  SELECT * FROM sales_a
  UNION ALL
  SELECT * FROM sales_b
) u
GROUP BY sm_type
HAVING SUM(total_paid) > 20000
ORDER BY aggregate_paid DESC
