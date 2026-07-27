WITH sales_agg AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    d.d_year AS year,
    'sales' AS metric_type,
    SUM(ss.ss_net_profit) AS amount,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS performance_category
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_store_id, s.s_store_name, d.d_year
  HAVING SUM(ss.ss_net_profit) <> 0
),
returns_agg AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    d.d_year AS year,
    'returns' AS metric_type,
    SUM(sr.sr_net_loss) AS amount,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS performance_category
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_store_id, s.s_store_name, d.d_year
  HAVING SUM(sr.sr_net_loss) <> 0
)
SELECT DISTINCT *
FROM (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM returns_agg
) combined
ORDER BY year DESC, amount DESC
LIMIT 100
