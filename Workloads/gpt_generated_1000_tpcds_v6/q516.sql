WITH store_sales_agg AS (
  SELECT
    c.c_customer_id AS cust_id,
    s.s_store_name AS description,
    SUM(ss.ss_net_profit) AS metric,
    CASE
      WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH'
      ELSE 'LOW'
    END AS category
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE s.s_floor_space > 6000000
    AND ss.ss_net_paid > 0
  GROUP BY c.c_customer_id, s.s_store_name
),
store_returns_agg AS (
  SELECT
    c.c_customer_id AS cust_id,
    r.r_reason_desc AS description,
    SUM(sr.sr_net_loss) AS metric,
    CASE
      WHEN SUM(sr.sr_net_loss) > 5000 THEN 'HIGH_LOSS'
      ELSE 'LOW_LOSS'
    END AS category
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_return_tax > 5.00
  GROUP BY c.c_customer_id, r.r_reason_desc
)
SELECT DISTINCT
  cust_id,
  description,
  metric,
  category
FROM (
  SELECT cust_id, description, metric, category FROM store_sales_agg
  UNION ALL
  SELECT cust_id, description, metric, category FROM store_returns_agg
) AS combined
ORDER BY metric DESC
LIMIT 100
