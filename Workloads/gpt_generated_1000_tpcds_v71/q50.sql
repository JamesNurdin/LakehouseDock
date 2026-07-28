WITH
  store_agg AS (
    SELECT
      i.i_item_id AS item_id,
      i.i_product_name AS product_name,
      'store' AS channel,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS order_cnt
    FROM tpcds.store_sales AS ss
    JOIN tpcds.item AS i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_wholesale_cost > 30.00
    GROUP BY i.i_item_id, i.i_product_name
  ),
  web_agg AS (
    SELECT
      i.i_item_id AS item_id,
      i.i_product_name AS product_name,
      'web' AS channel,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS order_cnt
    FROM tpcds.web_sales AS ws
    JOIN tpcds.item AS i
      ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_wholesale_cost > 30.00
    GROUP BY i.i_item_id, i.i_product_name
  ),
  combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  )
SELECT
  c.item_id,
  c.product_name,
  c.channel,
  c.total_sales,
  c.order_cnt,
  RANK() OVER (PARTITION BY c.channel ORDER BY c.total_sales DESC) AS sales_rank
FROM combined AS c
ORDER BY c.channel, sales_rank
LIMIT 100
