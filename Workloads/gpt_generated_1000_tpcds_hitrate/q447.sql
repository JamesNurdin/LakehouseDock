WITH
  store_agg AS (
    SELECT
      t.t_time_id,
      t.t_hour,
      t.t_am_pm,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ss.ss_customer_sk) AS uniq_customers,
      CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM store_sales ss
    RIGHT OUTER JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_customer_sk IN (
          SELECT cr_refunded_customer_sk
          FROM catalog_returns
          WHERE cr_return_amount > 1000
        )
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_returned_time_sk = t.t_time_sk
            AND cr2.cr_return_amount > 500
        )
    GROUP BY t.t_time_id, t.t_hour, t.t_am_pm
  ),
  web_agg AS (
    SELECT
      t.t_time_id,
      t.t_hour,
      t.t_am_pm,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS uniq_customers,
      CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM web_sales ws
    RIGHT OUTER JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_bill_customer_sk IN (
          SELECT cr_refunded_customer_sk
          FROM catalog_returns
          WHERE cr_return_amount > 1000
        )
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_returned_time_sk = t.t_time_sk
            AND cr2.cr_return_amount > 500
        )
    GROUP BY t.t_time_id, t.t_hour, t.t_am_pm
  )
SELECT DISTINCT
  time_id,
  hour,
  am_pm,
  total_sales,
  uniq_customers,
  sales_category,
  source
FROM (
  SELECT
    t_time_id AS time_id,
    t_hour AS hour,
    t_am_pm AS am_pm,
    total_sales,
    uniq_customers,
    sales_category,
    'store' AS source
  FROM store_agg
  UNION ALL
  SELECT
    t_time_id AS time_id,
    t_hour AS hour,
    t_am_pm AS am_pm,
    total_sales,
    uniq_customers,
    sales_category,
    'web' AS source
  FROM web_agg
) AS combined
ORDER BY time_id, source
LIMIT 100
