WITH
  sales_agg AS (
    SELECT
      s.s_store_name AS store_name,
      d.d_date AS sale_date,
      'Sales' AS metric_type,
      SUM(ss.ss_net_paid) AS total_amount,
      CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'High' ELSE 'Normal' END AS amount_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
    GROUP BY s.s_store_name, d.d_date
  ),
  returns_agg AS (
    SELECT
      s.s_store_name AS store_name,
      d.d_date AS sale_date,
      'Returns' AS metric_type,
      SUM(sr.sr_return_amt) AS total_amount,
      CASE WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High' ELSE 'Normal' END AS amount_category
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_state = 'CA'
    GROUP BY s.s_store_name, d.d_date
  )
SELECT
  store_name,
  sale_date,
  metric_type,
  total_amount,
  amount_category
FROM (
  SELECT store_name, sale_date, metric_type, total_amount, amount_category FROM sales_agg
  UNION ALL
  SELECT store_name, sale_date, metric_type, total_amount, amount_category FROM returns_agg
) combined
ORDER BY total_amount DESC, store_name
LIMIT 100
