WITH base AS (
  SELECT
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_item_sk,
    cp.cp_department,
    i.i_category,
    p.p_channel_dmail,
    td.t_hour,
    cd.cd_purchase_estimate
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_time_sk = td.t_time_sk
   AND ss.ss_cdemo_sk = cd.cd_demo_sk
   AND ss.ss_promo_sk = p.p_promo_sk
),

a1 AS (
  SELECT
    cp_department,
    i_category,
    SUM(cs_quantity) AS total_qty,
    AVG(cs_ext_sales_price) AS avg_price,
    COUNT(DISTINCT cs_item_sk) AS distinct_items,
    MIN(cs_ext_sales_price) AS min_price,
    MAX(cs_ext_sales_price) AS max_price,
    (
      SELECT COUNT(DISTINCT ss2.ss_item_sk)
      FROM store_sales ss2
      JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
      WHERE i2.i_category = i_category
    ) AS category_store_sales_item_cnt
  FROM base
  WHERE cp_department = 'Books'
    AND p_channel_dmail = 'Y'
    AND t_hour BETWEEN 8 AND 12
    AND cd_purchase_estimate > 6000
  GROUP BY cp_department, i_category
),

a2 AS (
  SELECT
    cp_department,
    i_category,
    SUM(cs_quantity) AS total_qty,
    AVG(cs_ext_sales_price) AS avg_price,
    COUNT(DISTINCT cs_item_sk) AS distinct_items,
    MIN(cs_ext_sales_price) AS min_price,
    MAX(cs_ext_sales_price) AS max_price,
    (
      SELECT COUNT(DISTINCT ss2.ss_item_sk)
      FROM store_sales ss2
      JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
      WHERE i2.i_category = i_category
    ) AS category_store_sales_item_cnt
  FROM base
  WHERE cp_department = 'Electronics'
    AND p_channel_dmail = 'N'
    AND t_hour BETWEEN 10 AND 14
    AND cd_purchase_estimate > 4000
  GROUP BY cp_department, i_category
),

a3 AS (
  SELECT
    cp_department,
    i_category,
    SUM(cs_quantity) AS total_qty,
    AVG(cs_ext_sales_price) AS avg_price,
    COUNT(DISTINCT cs_item_sk) AS distinct_items,
    MIN(cs_ext_sales_price) AS min_price,
    MAX(cs_ext_sales_price) AS max_price,
    (
      SELECT COUNT(DISTINCT ss2.ss_item_sk)
      FROM store_sales ss2
      JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
      WHERE i2.i_category = i_category
    ) AS category_store_sales_item_cnt
  FROM base
  WHERE cp_department = 'Books'
    AND p_channel_dmail = 'Y'
    AND t_hour BETWEEN 8 AND 12
    AND cd_purchase_estimate > 5000
  GROUP BY cp_department, i_category
),

a4 AS (
  SELECT
    cp_department,
    i_category,
    SUM(cs_quantity) AS total_qty,
    AVG(cs_ext_sales_price) AS avg_price,
    COUNT(DISTINCT cs_item_sk) AS distinct_items,
    MIN(cs_ext_sales_price) AS min_price,
    MAX(cs_ext_sales_price) AS max_price,
    (
      SELECT COUNT(DISTINCT ss2.ss_item_sk)
      FROM store_sales ss2
      JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
      WHERE i2.i_category = i_category
    ) AS category_store_sales_item_cnt
  FROM base
  WHERE cp_department = 'Electronics'
    AND p_channel_dmail = 'N'
    AND t_hour BETWEEN 10 AND 14
    AND cd_purchase_estimate > 4500
  GROUP BY cp_department, i_category
)
SELECT *
FROM (
  SELECT * FROM a1
  UNION DISTINCT
  SELECT * FROM a2
) AS u
EXCEPT
SELECT * FROM a3
INTERSECT
SELECT * FROM a4
ORDER BY total_qty DESC
OFFSET 20
LIMIT 100
