WITH sales_metrics AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    'Sales' AS metric_type,
    SUM(ss.ss_ext_sales_price) AS metric_value,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS level,
    (
      SELECT COUNT(DISTINCT sr_inner.sr_ticket_number)
      FROM store_returns sr_inner
      WHERE sr_inner.sr_store_sk = s.s_store_sk
    ) AS auxiliary
  FROM store s
  RIGHT OUTER JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  WHERE p.p_cost > 500 OR p.p_cost IS NULL
  GROUP BY s.s_store_id, s.s_store_name, s.s_store_sk
),
returns_metrics AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    'Returns' AS metric_type,
    SUM(sr.sr_return_amt) AS metric_value,
    CASE WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS level,
    (
      SELECT COUNT(DISTINCT ss_inner.ss_ticket_number)
      FROM store_sales ss_inner
      WHERE ss_inner.ss_store_sk = s.s_store_sk
    ) AS auxiliary
  FROM store s
  RIGHT OUTER JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
  WHERE EXISTS (
    SELECT 1 FROM promotion p2
    WHERE p2.p_promo_id = 'PROMO_001' AND p2.p_cost > 500
  )
  GROUP BY s.s_store_id, s.s_store_name, s.s_store_sk
)
SELECT *
FROM sales_metrics
UNION
SELECT *
FROM returns_metrics
ORDER BY s_store_id, metric_type
