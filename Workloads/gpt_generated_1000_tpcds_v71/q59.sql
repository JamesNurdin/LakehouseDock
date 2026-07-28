WITH
  store_agg AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_class_id,
      SUM(ss.ss_ext_sales_price) AS store_sales_total,
      AVG(ss.ss_sales_price) AS store_avg_price,
      COUNT(*) AS store_txn_cnt
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_class_id = 13
      AND i.i_container = 'Unknown'
      AND ss.ss_sales_price > 10
    GROUP BY i.i_item_sk, i.i_product_name, i.i_class_id
  ),
  web_agg AS (
    SELECT
      ws.ws_item_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_total,
      AVG(ws.ws_sales_price) AS web_avg_price,
      COUNT(*) AS web_txn_cnt,
      MAX(ws.ws_list_price) AS max_list_price
    FROM tpcds.web_sales ws
    JOIN tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
      AND ws.ws_list_price BETWEEN 60 AND 130
    GROUP BY ws.ws_item_sk
  )
SELECT
  s.i_product_name,
  s.i_class_id,
  s.store_sales_total,
  w.web_sales_total,
  CASE
    WHEN s.store_sales_total > w.web_sales_total THEN 'Store Higher'
    WHEN s.store_sales_total < w.web_sales_total THEN 'Web Higher'
    ELSE 'Equal'
  END AS sales_comparison,
  (
    SELECT COUNT(*)
    FROM tpcds.store_sales ss2
    WHERE ss2.ss_item_sk = s.i_item_sk
      AND ss2.ss_quantity > 5
  ) AS high_qty_store_txns
FROM store_agg s
JOIN web_agg w
  ON w.ws_item_sk = s.i_item_sk
ORDER BY s.store_sales_total DESC
LIMIT 100
