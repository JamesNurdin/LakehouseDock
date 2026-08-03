WITH
  catalog_agg AS (
    SELECT
      cs.cs_item_sk AS item_sk,
      SUM(cs.cs_net_paid_inc_ship) AS catalog_net_sales,
      COUNT(*) AS catalog_orders,
      MIN(cs.cs_sold_date_sk) AS first_sold_date_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND CAST(cs.cs_ext_sales_price AS VARCHAR) LIKE '7%'
    GROUP BY cs.cs_item_sk
  ),
  store_agg AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      SUM(ss.ss_net_paid) AS store_net_sales,
      COUNT(*) AS store_transactions
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND ss.ss_sales_price > 500
    GROUP BY ss.ss_item_sk
  ),
  intersect_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE REGEXP_LIKE(CAST(cs.cs_ext_sales_price AS VARCHAR), '^7[0-9]{2}\\..*')
    INTERSECT
    SELECT ss.ss_item_sk
    FROM store_sales ss
    WHERE ss.ss_sales_price > 500
  ),
  full_join AS (
    SELECT
      COALESCE(ca.item_sk, sa.item_sk) AS item_sk,
      ca.catalog_net_sales,
      ca.catalog_orders,
      sa.store_net_sales,
      sa.store_transactions
    FROM catalog_agg ca
    FULL OUTER JOIN store_agg sa
      ON ca.item_sk = sa.item_sk
  )
SELECT
  i.i_item_id,
  i.i_item_desc,
  i.i_category,
  COALESCE(fj.catalog_net_sales, 0) AS catalog_net_sales,
  COALESCE(fj.store_net_sales, 0) AS store_net_sales,
  (COALESCE(fj.catalog_net_sales, 0) + COALESCE(fj.store_net_sales, 0)) AS total_net_sales,
  CASE
    WHEN REGEXP_LIKE(i.i_item_desc, '(?i)premium') THEN 'Premium'
    WHEN REGEXP_LIKE(i.i_item_desc, '(?i)deluxe') THEN 'Deluxe'
    ELSE 'Standard'
  END AS item_tier,
  CONCAT(SUBSTRING(i.i_product_name, 1, 3), '-', i.i_brand) AS product_brand_code
FROM full_join fj
RIGHT OUTER JOIN item i
  ON i.i_item_sk = fj.item_sk
WHERE i.i_item_sk IN (SELECT item_sk FROM intersect_items)
  AND i.i_category LIKE 'Electronics%'
ORDER BY total_net_sales DESC
LIMIT 100
