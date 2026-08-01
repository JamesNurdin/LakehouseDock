WITH
  sales_base AS (
    SELECT
      i.i_brand,
      td.t_hour,
      ss.ss_ext_sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)organic')
      AND c.c_preferred_cust_flag = 'Y'
  ),
  sales_agg AS (
    SELECT
      i_brand,
      t_hour,
      SUM(ss_ext_sales_price) AS total_sales
    FROM sales_base
    GROUP BY i_brand, t_hour
  ),
  sales_with_rank AS (
    SELECT
      i_brand,
      t_hour,
      total_sales,
      ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS brand_sales_rank
    FROM sales_agg
  ),
  returns_base AS (
    SELECT
      i.i_brand,
      td.t_hour,
      cr.cr_return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)organic')
      AND c.c_preferred_cust_flag = 'N'
  ),
  returns_agg AS (
    SELECT
      i_brand,
      t_hour,
      SUM(cr_return_amount) AS total_returns
    FROM returns_base
    GROUP BY i_brand, t_hour
  ),
  combined AS (
    SELECT
      i_brand,
      t_hour,
      total_sales,
      NULL AS total_returns,
      brand_sales_rank
    FROM sales_with_rank
    UNION ALL
    SELECT
      i_brand,
      t_hour,
      NULL,
      total_returns,
      NULL
    FROM returns_agg
  ),
  key_set AS (
    SELECT i_brand, t_hour
    FROM combined
    WHERE i_brand LIKE 'brand%'
  ),
  intersect_set AS (
    SELECT i_brand, t_hour
    FROM returns_agg
    WHERE i_brand LIKE '%brand%'
  )
SELECT
  c.i_brand,
  c.t_hour,
  SUM(c.total_sales) AS sum_sales,
  SUM(c.total_returns) AS sum_returns,
  MAX(c.brand_sales_rank) AS max_brand_sales_rank,
  regexp_extract(c.i_brand, '(brand.*)', 1) AS extracted_brand,
  ROW_NUMBER() OVER (ORDER BY c.i_brand, c.t_hour) AS global_row_num
FROM combined c
WHERE (c.i_brand, c.t_hour) IN (
  SELECT i_brand, t_hour FROM key_set
  INTERSECT
  SELECT i_brand, t_hour FROM intersect_set
)
GROUP BY GROUPING SETS (
  (c.i_brand, c.t_hour),
  (c.i_brand),
  ()
)
ORDER BY c.i_brand, c.t_hour
LIMIT 100
