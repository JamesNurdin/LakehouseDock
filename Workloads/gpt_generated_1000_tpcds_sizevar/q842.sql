WITH
  cs AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_ext_sales_price,
      cs.cs_ext_discount_amt,
      cp.cp_department,
      w.w_warehouse_name
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_department = 'DEPARTMENT'
  ),
  cr AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      w.w_warehouse_name AS return_warehouse
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 0
  ),
  full_sales AS (
    SELECT
      COALESCE(cs.cs_order_number, cr.cr_order_number) AS order_number,
      cs.cs_item_sk,
      cr.cr_return_amount,
      cs.cs_ext_sales_price,
      cr.cr_return_quantity,
      cs.cp_department,
      cs.w_warehouse_name
    FROM cs
    FULL OUTER JOIN cr ON cs.cs_order_number = cr.cr_order_number
  ),
  agg1 AS (
    SELECT
      COUNT(DISTINCT cs_item_sk)          AS distinct_items,
      COUNT(DISTINCT order_number)        AS distinct_orders,
      SUM(cs_ext_sales_price)             AS total_sales,
      SUM(cr_return_amount)               AS total_returns
    FROM full_sales
    WHERE cs_ext_sales_price IS NOT NULL OR cr_return_amount IS NOT NULL
  ),
  max_income AS (
    SELECT MAX(ib_upper_bound) AS max_upper FROM income_band
  ),
  sales_only_orders AS (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT cr_order_number FROM catalog_returns
  ),
  time_subset AS (
    SELECT t_time_sk FROM time_dim WHERE t_hour IN (9, 10)
  ),
  cross_set AS (
    SELECT ts.t_time_sk, seq.num
    FROM time_subset ts
    CROSS JOIN (
      SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3
    ) seq
  ),
  union_sales AS (
    SELECT ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_item_sk      AS item_sk,
           ss.ss_ext_sales_price AS ext_sales_price,
           'store' AS channel
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
    UNION
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_ext_sales_price,
           'web' AS channel
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
  )
SELECT
  agg1.distinct_items,
  agg1.distinct_orders,
  agg1.total_sales,
  agg1.total_returns,
  max_income.max_upper,
  (SELECT COUNT(*) FROM sales_only_orders)            AS sales_only_order_count,
  (SELECT COUNT(*) FROM cross_set)                    AS cross_set_rows,
  (SELECT COUNT(DISTINCT item_sk)    FROM union_sales) AS distinct_items_union,
  (SELECT COUNT(DISTINCT channel)   FROM union_sales) AS distinct_channels_union
FROM agg1
CROSS JOIN max_income
WHERE EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk = 1)
LIMIT 100
