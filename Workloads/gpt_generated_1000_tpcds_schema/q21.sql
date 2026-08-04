WITH
  store_part AS (
    SELECT
      ss.ss_store_sk AS store_sk,
      d.d_year AS year,
      ss.ss_item_sk AS item_sk,
      SUM(ss.ss_ext_sales_price) AS sales_amount,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN "store" s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY GROUPING SETS (
      (ss.ss_store_sk, d.d_year, ss.ss_item_sk),
      (ss.ss_store_sk, d.d_year)
    )
  ),
  catalog_part AS (
    SELECT
      cs.cs_bill_customer_sk AS store_sk,
      d.d_year AS year,
      cs.cs_item_sk AS item_sk,
      SUM(cs.cs_ext_sales_price) AS sales_amount,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS (
      (cs.cs_bill_customer_sk, d.d_year, cs.cs_item_sk),
      (cs.cs_bill_customer_sk, d.d_year)
    )
  ),
  union_all AS (
    SELECT store_sk, year, item_sk, sales_amount, sales_cnt FROM store_part
    UNION ALL
    SELECT store_sk, year, item_sk, sales_amount, sales_cnt FROM catalog_part
  ),
  aggregated AS (
    SELECT
      u.store_sk,
      u.year,
      SUM(u.sales_amount) AS total_sales_amount,
      SUM(u.sales_cnt) AS total_sales_cnt
    FROM union_all u
    WHERE u.store_sk NOT IN (
      SELECT ss_item_sk FROM store_sales WHERE ss_quantity > 1000
    )
    GROUP BY u.store_sk, u.year
  ),
  reasons AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_sk IN (10, 15, 16)
  ),
  years AS (
    SELECT DISTINCT d_year AS year
    FROM date_dim
    WHERE d_year IN (2001, 2002)
  )
SELECT
  r.r_reason_desc,
  y.year,
  COALESCE(a.total_sales_amount, 0) AS total_sales_amount,
  COALESCE(a.total_sales_cnt, 0) AS total_sales_cnt
FROM reasons r
CROSS JOIN years y
LEFT JOIN aggregated a ON a.year = y.year
ORDER BY r.r_reason_desc, y.year
LIMIT 100
