WITH
  -- Items sold in stores where the store city starts with 'A' and the store city matches a regex
  store_items AS (
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE 'A%'
      AND regexp_like(s.s_city, '^A')
  ),
  -- Items sold online where the website name contains 'shop' and the manufacturer contains the substring 'cally'
  web_items AS (
    SELECT DISTINCT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE wsite.web_name LIKE '%shop%'
      AND regexp_like(i.i_manufact, 'cally')
  ),
  -- Items appearing in both previous sets
  intersect_items AS (
    SELECT item_sk FROM store_items
    INTERSECT
    SELECT item_sk FROM web_items
  ),
  -- All items that appear in catalog sales for categories that start with 'Elect'
  catalog_items AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_category LIKE 'Elect%'
  ),
  -- All items that appear in store sales (any store)
  store_items_all AS (
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM store_sales ss
  ),
  -- Items in catalog but never sold in a store
  except_items AS (
    SELECT item_sk FROM catalog_items
    EXCEPT
    SELECT item_sk FROM store_items_all
  ),
  -- LATERAL subquery to compute the length of the manufacturer name for each item
  item_with_len AS (
    SELECT i.i_item_sk,
           i.i_manufact,
           i.i_category,
           i.i_product_name,
           m.manuf_len
    FROM item i
    CROSS JOIN LATERAL (
      SELECT length(i.i_manufact) AS manuf_len
    ) AS m
  ),
  -- Aggregated sales for items that are in the intersection set
  agg_sales AS (
    SELECT
      ii.item_sk,
      i.i_manufact,
      i.i_category,
      SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales,
      SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
      COUNT(DISTINCT ws.ws_order_number) AS web_txns,
      il.manuf_len
    FROM intersect_items ii
    JOIN item i ON ii.item_sk = i.i_item_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN item_with_len il ON il.i_item_sk = i.i_item_sk
    GROUP BY ii.item_sk, i.i_manufact, i.i_category, il.manuf_len
  ),
  -- Summary of catalog sales per item
  catalog_summary AS (
    SELECT
      cs.cs_item_sk AS item_sk,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
      COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
  )
SELECT
  a.item_sk,
  a.i_manufact,
  a.i_category,
  a.store_sales,
  a.web_sales,
  a.store_txns,
  a.web_txns,
  a.manuf_len,
  -- scalar subquery: average sales price in catalog for this manufacturer
  (
    SELECT avg(cs.cs_sales_price)
    FROM catalog_sales cs
    JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
    WHERE i2.i_manufact = a.i_manufact
  ) AS avg_catalog_price,
  -- existence check: any preferred customer bought this item in a store
  EXISTS (
    SELECT 1
    FROM store_sales ss2
    JOIN customer c2 ON ss2.ss_customer_sk = c2.c_customer_sk
    WHERE ss2.ss_item_sk = a.item_sk
      AND c2.c_preferred_cust_flag = 'Y'
  ) AS has_preferred_customer,
  -- flag indicating the item is in the EXCEPT set (catalog but never sold in store)
  CASE WHEN ei.item_sk IS NOT NULL THEN true ELSE false END AS is_never_store_sold,
  -- catalog aggregates (may be null for items not present in catalog)
  cat.catalog_sales_total,
  cat.catalog_orders
FROM agg_sales a
FULL OUTER JOIN catalog_summary cat ON cat.item_sk = a.item_sk
LEFT JOIN except_items ei ON ei.item_sk = a.item_sk
ORDER BY a.store_sales DESC
LIMIT 100
