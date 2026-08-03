WITH
  sales_agg AS (
    SELECT
      s.s_store_id,
      d.d_year,
      i.i_item_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      CONCAT(s.s_store_name, ' ', CAST(d.d_year AS varchar)) AS store_year_label,
      regexp_extract(i.i_product_name, '^(.{3})', 1) AS product_prefix
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '[A-Z]{3}')
      AND s.s_store_name LIKE '%Market%'
    GROUP BY s.s_store_id, d.d_year, i.i_item_sk, s.s_store_name, i.i_product_name
  ),
  items_1999 AS (
    SELECT DISTINCT i.i_item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 1999
  ),
  items_2000 AS (
    SELECT DISTINCT i.i_item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
  ),
  items_only_1999 AS (
    SELECT i_item_sk FROM items_1999
    EXCEPT
    SELECT i_item_sk FROM items_2000
  ),
  items_both AS (
    SELECT i_item_sk FROM items_1999
    INTERSECT
    SELECT i_item_sk FROM items_2000
  ),
  year_vals AS (
    SELECT 1999 AS yr UNION ALL SELECT 2000 AS yr
  ),
  num_vals AS (
    SELECT 1 AS n UNION ALL SELECT 2 AS n UNION ALL SELECT 3 AS n
  ),
  year_num_cross AS (
    SELECT yr, n FROM year_vals CROSS JOIN num_vals
  )
SELECT
  sa.s_store_id,
  sa.d_year,
  sa.i_item_sk,
  sa.total_sales,
  sa.sales_cnt,
  sa.store_year_label,
  sa.product_prefix,
  ync.yr,
  ync.n
FROM sales_agg sa
JOIN year_num_cross ync ON sa.d_year = ync.yr
WHERE sa.i_item_sk IN (SELECT i_item_sk FROM items_only_1999)
ORDER BY sa.total_sales DESC
LIMIT 100
