/*
  Goal: Identify high‑value sales of items in the 'Sports' category from both the store and web channels, excluding any items that have been returned. The result shows the sales channel, store identifier (null for web), item identifier, net amount paid and quantity, limited to the first 100 rows.
*/
SELECT
  'STORE' AS channel,
  s.s_store_id AS store_id,
  i.i_item_id AS item_id,
  ss.ss_net_paid AS net_paid,
  ss.ss_quantity AS quantity
FROM
  store_sales ss
  INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
  INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
  INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE
  i.i_category = 'Sports'
  AND ss.ss_net_paid > 1000
  AND NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_item_sk = ss.ss_item_sk
  )
UNION ALL
SELECT
  'WEB' AS channel,
  NULL AS store_id,
  i.i_item_id AS item_id,
  ws.ws_net_paid_inc_ship AS net_paid,
  ws.ws_quantity AS quantity
FROM
  web_sales ws
  INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
  INNER JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE
  i.i_category = 'Sports'
  AND ws.ws_net_paid_inc_ship > 1000
  AND NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = ws.ws_item_sk
  )
LIMIT 100
