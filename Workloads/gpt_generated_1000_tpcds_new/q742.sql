WITH
  sampled_store_sales AS (
    SELECT ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (5)
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451249
  ),
  store_agg AS (
    SELECT i.i_item_id   AS item_id,
           i.i_product_name AS item_name,
           SUM(ss.ss_quantity)   AS total_quantity_sold,
           SUM(ss.ss_net_paid)   AS total_net_paid
    FROM sampled_store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name
  ),
  web_agg AS (
    SELECT i.i_item_id   AS item_id,
           i.i_product_name AS item_name,
           SUM(ws.ws_quantity)   AS total_quantity_sold,
           SUM(ws.ws_net_paid)   AS total_net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451249
    GROUP BY i.i_item_id, i.i_product_name
  ),
  combined_sales AS (
    SELECT item_id,
           item_name,
           total_quantity_sold,
           total_net_paid
    FROM store_agg
    UNION
    SELECT item_id,
           item_name,
           total_quantity_sold,
           total_net_paid
    FROM web_agg
  ),
  store_return_agg AS (
    SELECT i.i_item_id   AS item_id,
           i.i_product_name AS item_name,
           SUM(sr.sr_return_amt) AS store_return_amt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2451249
    GROUP BY i.i_item_id, i.i_product_name
  ),
  web_return_agg AS (
    SELECT i.i_item_id   AS item_id,
           i.i_product_name AS item_name,
           SUM(wr.wr_return_amt) AS web_return_amt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451249
    GROUP BY i.i_item_id, i.i_product_name
  ),
  returns_full AS (
    SELECT COALESCE(s.item_id, w.item_id)   AS item_id,
           COALESCE(s.item_name, w.item_name) AS item_name,
           s.store_return_amt,
           w.web_return_amt
    FROM store_return_agg s
    FULL OUTER JOIN web_return_agg w
      ON s.item_id = w.item_id
  )
SELECT
  cs.item_id,
  cs.item_name,
  cs.total_quantity_sold,
  cs.total_net_paid,
  rf.store_return_amt,
  rf.web_return_amt
FROM combined_sales cs
LEFT JOIN returns_full rf
  ON cs.item_id = rf.item_id
ORDER BY cs.total_net_paid DESC
LIMIT 100
