/*
  Goal: Identify recent (2022) orders that were sold through both catalog and web channels, have not been returned, and analyze their combined net profit while linking each order to a small set of household demographics. The query demonstrates advanced Trino features: CTEs, TABLESAMPLE, set operations (INTERSECT, UNION, EXCEPT), a scalar sub‑query, and a CROSS JOIN.
*/
WITH
  recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  ),

  sampled_catalog AS (
    SELECT cs_order_number,
           cs_net_profit,
           cs_sold_date_sk
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)
  ),

  sampled_web AS (
    SELECT ws_order_number,
           ws_net_profit,
           ws_sold_date_sk
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)
  ),

  catalog_order_profit AS (
    SELECT cs_order_number AS order_id,
           SUM(cs_net_profit) AS catalog_profit
    FROM sampled_catalog sc
    JOIN date_dim d ON sc.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY cs_order_number
  ),

  web_order_profit AS (
    SELECT ws_order_number AS order_id,
           SUM(ws_net_profit) AS web_profit
    FROM sampled_web sw
    JOIN date_dim d ON sw.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ws_order_number
  ),

  common_orders AS (
    SELECT order_id FROM catalog_order_profit
    INTERSECT
    SELECT order_id FROM web_order_profit
  ),

  returned_orders AS (
    SELECT cr.cr_order_number AS order_id
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    UNION
    SELECT wr.wr_order_number AS order_id
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
  ),

  non_returned_common AS (
    SELECT order_id FROM common_orders
    EXCEPT
    SELECT order_id FROM returned_orders
  ),

  demo_subset AS (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_income_band_sk = 5
    LIMIT 3
  )
SELECT
  nrc.order_id,
  d.hd_demo_sk,
  (SELECT AVG(cs_net_profit) FROM sampled_catalog) AS avg_catalog_profit,
  COALESCE(cop.catalog_profit, 0) + COALESCE(wop.web_profit, 0) AS total_net_profit
FROM non_returned_common nrc
CROSS JOIN demo_subset d
LEFT JOIN catalog_order_profit cop ON cop.order_id = nrc.order_id
LEFT JOIN web_order_profit wop ON wop.order_id = nrc.order_id
LIMIT 100
