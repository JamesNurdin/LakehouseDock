/* goal: Identify catalog pages that generated the highest net revenue from items that were sold both in stores and online, where the item description contains a three‑digit code and belongs to the 'accessories' class. The query demonstrates string processing, sampling, set intersection, a right outer join, aggregation, and pagination. */
WITH
  -- Sampled store sales per item
  store_items AS (
    SELECT
      ss.ss_item_sk AS i_item_sk,
      SUM(ss.ss_net_paid) AS store_net_paid
    FROM
      store_sales ss TABLESAMPLE BERNOULLI (10)
    WHERE
      ss.ss_net_paid > 0
    GROUP BY
      ss.ss_item_sk
    HAVING
      SUM(ss.ss_net_paid) > 1000
  ),
  -- Sampled web sales per item
  web_items AS (
    SELECT
      ws.ws_item_sk AS i_item_sk,
      SUM(ws.ws_net_paid) AS web_net_paid
    FROM
      web_sales ws TABLESAMPLE BERNOULLI (5)
    WHERE
      ws.ws_net_paid > 0
    GROUP BY
      ws.ws_item_sk
    HAVING
      SUM(ws.ws_net_paid) > 500
  ),
  -- Items sold in BOTH channels
  intersect_items AS (
    SELECT i_item_sk FROM store_items
    INTERSECT
    SELECT i_item_sk FROM web_items
  ),
  -- Enrich intersected items with string processing
  item_detail AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_item_desc,
      regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word,
      concat(i.i_brand, ' ', i.i_product_name) AS brand_product,
      i.i_class,
      i.i_color
    FROM
      item i
      JOIN intersect_items ii ON i.i_item_sk = ii.i_item_sk
    WHERE
      regexp_like(i.i_item_desc, '[0-9]{3}')
      AND i.i_class LIKE '%accessories%'
  ),
  -- Aggregate catalog sales for the intersected items
  catalog_sales_agg AS (
    SELECT
      cs.cs_catalog_page_sk,
      cs.cs_item_sk,
      SUM(cs.cs_net_paid) AS page_item_net_paid
    FROM
      catalog_sales cs
      JOIN intersect_items ii ON cs.cs_item_sk = ii.i_item_sk
    GROUP BY
      cs.cs_catalog_page_sk,
      cs.cs_item_sk
  )
SELECT
  cp.cp_catalog_page_id,
  cp.cp_department,
  cp.cp_catalog_number,
  SUM(csa.page_item_net_paid) AS total_net_paid,
  COUNT(DISTINCT csa.cs_item_sk) AS distinct_items_sold,
  MAX(id.first_word) AS example_first_word
FROM
  catalog_sales_agg csa
  RIGHT OUTER JOIN catalog_page cp ON csa.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN item_detail id ON id.i_item_sk = csa.cs_item_sk
GROUP BY
  cp.cp_catalog_page_id,
  cp.cp_department,
  cp.cp_catalog_number
HAVING
  SUM(csa.page_item_net_paid) > 2000
ORDER BY
  total_net_paid DESC
OFFSET 0 LIMIT 100
