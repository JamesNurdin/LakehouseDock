/*
Goal: Identify the top‑selling items (by net profit) that have a numeric pattern in their description and were sold through web sites whose name starts with "Web" and via warehouses in cities containing "York". The query categorises profit levels, shows the average promotional cost per item, and limits the result to the top 100 rows.
*/
WITH
  /* Sample a fraction of web sales to reduce data volume */
  sample_sales AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
  ),

  /* Items whose description contains a three‑digit number */
  item_digit AS (
    SELECT i_item_sk
    FROM item
    WHERE regexp_like(i_item_desc, '\\d{3}')
  ),

  /* Promotions that were sent by e‑mail */
  promo_email AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_channel_email = 'Y'
  ),

  /* Intersection of items that both have a numeric description pattern and are linked to an e‑mail promotion */
  intersect_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_item_sk IN (
      SELECT p_item_sk FROM promotion WHERE p_channel_email = 'Y'
    )
    INTERSECT
    SELECT i_item_sk FROM item_digit
  ),

  /* Aggregation of sales by item and web site */
  agg_sales AS (
    SELECT
      i.i_item_sk,
      w.web_site_sk,
      w.web_name,
      SUM(ws.ws_quantity)                AS total_qty,
      SUM(ws.ws_net_profit)               AS total_profit,
      COUNT(*)                            AS order_cnt,
      CASE
        WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(ws.ws_net_profit) >  50000 THEN 'MEDIUM'
        ELSE 'LOW'
      END                                 AS profit_category
    FROM sample_sales ws
    JOIN item i       ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w   ON ws.ws_web_site_sk = w.web_site_sk
    WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
      AND regexp_like(w.web_name, '^Web.*')
      AND w.web_city LIKE 'New%'
    GROUP BY i.i_item_sk, w.web_site_sk, w.web_name
  ),

  /* Aggregation of sales by item and warehouse */
  agg_warehouse AS (
    SELECT
      i.i_item_sk,
      wa.w_warehouse_sk,
      wa.w_city,
      SUM(ws.ws_quantity)                AS total_qty,
      SUM(ws.ws_net_profit)               AS total_profit,
      CASE
        WHEN SUM(ws.ws_net_profit) > 80000 THEN 'HIGH_W'
        ELSE 'LOW_W'
      END                                 AS profit_category
    FROM sample_sales ws
    JOIN item i       ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse wa ON ws.ws_warehouse_sk = wa.w_warehouse_sk
    WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
      AND wa.w_city LIKE '%York%'
    GROUP BY i.i_item_sk, wa.w_warehouse_sk, wa.w_city
  ),

  /* Union of the two aggregation streams (distinct rows) */
  union_agg AS (
    SELECT i_item_sk, total_qty, total_profit, profit_category FROM agg_sales
    UNION
    SELECT i_item_sk, total_qty, total_profit, profit_category FROM agg_warehouse
  )

SELECT
  u.i_item_sk,
  CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product_name,
  SUM(u.total_qty)               AS sum_qty,
  SUM(u.total_profit)            AS sum_profit,
  (SELECT AVG(p.p_cost) FROM promotion p WHERE p.p_item_sk = u.i_item_sk) AS avg_promo_cost,
  MAX(u.profit_category)         AS overall_category
FROM union_agg u
JOIN item i ON u.i_item_sk = i.i_item_sk
GROUP BY u.i_item_sk, i.i_brand, i.i_product_name
ORDER BY sum_profit DESC
LIMIT 100
