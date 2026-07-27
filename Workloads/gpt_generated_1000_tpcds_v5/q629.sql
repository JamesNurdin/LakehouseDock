WITH
  catalog_agg AS (
    SELECT
      cs.cs_item_sk AS i_item_sk,
      SUM(cs.cs_net_profit) AS catalog_net_profit,
      SUM(cs.cs_ext_sales_price) AS catalog_ext_sales
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship > 1000
    GROUP BY cs.cs_item_sk
  ),
  store_agg AS (
    SELECT
      ss.ss_item_sk AS i_item_sk,
      SUM(ss.ss_net_profit) AS store_net_profit,
      SUM(ss.ss_ext_sales_price) AS store_ext_sales
    FROM store_sales ss
    WHERE ss.ss_quantity > 1
    GROUP BY ss.ss_item_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_item_sk AS i_item_sk,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(ws.ws_ext_sales_price) AS web_ext_sales,
      AVG(ws.ws_wholesale_cost) AS avg_ws_wholesale_cost
    FROM web_sales ws
    WHERE ws.ws_wholesale_cost BETWEEN 45 AND 85
    GROUP BY ws.ws_item_sk
  ),
  item_filtered AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      i.i_category_id,
      i.i_brand
    FROM item i
    WHERE i.i_category_id IN (2, 4, 9)
      AND i.i_brand LIKE '%amalg%'
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_category_id,
  i.i_brand,
  ca.catalog_net_profit,
  st.store_net_profit,
  wb.web_net_profit,
  COALESCE(ca.catalog_net_profit, 0) + COALESCE(st.store_net_profit, 0) + COALESCE(wb.web_net_profit, 0) AS total_net_profit,
  wb.avg_ws_wholesale_cost,
  RANK() OVER (ORDER BY COALESCE(ca.catalog_net_profit, 0) + COALESCE(st.store_net_profit, 0) + COALESCE(wb.web_net_profit, 0) DESC) AS profit_rank
FROM item_filtered i
LEFT JOIN catalog_agg ca ON ca.i_item_sk = i.i_item_sk
LEFT JOIN store_agg st ON st.i_item_sk = i.i_item_sk
LEFT JOIN web_agg wb ON wb.i_item_sk = i.i_item_sk
WHERE EXISTS (
  SELECT 1
  FROM store_sales ss2
  WHERE ss2.ss_item_sk = i.i_item_sk
    AND ss2.ss_quantity > 5
)
ORDER BY profit_rank
LIMIT 100
