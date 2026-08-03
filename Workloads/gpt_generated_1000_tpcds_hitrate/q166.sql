WITH store_agg AS (
  SELECT
    td.t_hour,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE p.p_channel_radio = 'N'
    AND td.t_am_pm = 'PM'
    AND EXISTS (
      SELECT 1 FROM store s
      WHERE s.s_store_sk = ss.ss_store_sk
        AND s.s_state = 'CA'
    )
  GROUP BY td.t_hour, p.p_promo_name
),
catalog_agg AS (
  SELECT
    td.t_hour,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE p.p_channel_radio = 'N'
    AND td.t_am_pm = 'PM'
    AND p.p_response_target > (
      SELECT AVG(p2.p_response_target) FROM promotion p2
    )
  GROUP BY td.t_hour, p.p_promo_name
)
SELECT
  combined.t_hour,
  combined.p_promo_name,
  combined.total_net_paid,
  combined.total_discount,
  combined.sales_cnt,
  combined.sales_source
FROM (
  SELECT
    t_hour,
    p_promo_name,
    total_net_paid,
    total_discount,
    sales_cnt,
    'store' AS sales_source
  FROM store_agg
  UNION ALL
  SELECT
    t_hour,
    p_promo_name,
    total_net_paid,
    total_discount,
    sales_cnt,
    'catalog' AS sales_source
  FROM catalog_agg
) combined
ORDER BY combined.t_hour, combined.total_net_paid DESC
LIMIT 100
