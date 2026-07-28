WITH item_avg_price AS (
   SELECT i_item_sk,
          AVG(i_current_price) AS avg_price
   FROM item
   GROUP BY i_item_sk
),
union_sales AS (
   SELECT
       c.c_customer_id          AS customer_id,
       i.i_item_id              AS item_id,
       SUM(ss.ss_net_paid)      AS total_sales,
       'store'                  AS channel,
       CASE WHEN SUM(ss.ss_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
       (SUM(ss.ss_net_paid) - (
            SELECT avg_price
            FROM item_avg_price ap
            WHERE ap.i_item_sk = i.i_item_sk
       )) AS price_diff
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_rec_start_date <= DATE '2001-01-01'
     AND EXISTS (
         SELECT 1
         FROM inventory inv
         WHERE inv.inv_item_sk = i.i_item_sk
           AND inv.inv_quantity_on_hand > 0
     )
     AND NOT EXISTS (
         SELECT 1
         FROM store_returns sr
         WHERE sr.sr_customer_sk = c.c_customer_sk
           AND sr.sr_item_sk = i.i_item_sk
     )
   GROUP BY c.c_customer_id, i.i_item_id, i.i_item_sk
   UNION ALL
   SELECT
       c.c_customer_id          AS customer_id,
       i.i_item_id              AS item_id,
       SUM(ws.ws_net_paid)      AS total_sales,
       'web'                    AS channel,
       CASE WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
       (SUM(ws.ws_net_paid) - (
            SELECT avg_price
            FROM item_avg_price ap
            WHERE ap.i_item_sk = i.i_item_sk
       )) AS price_diff
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE i.i_rec_start_date <= DATE '2001-01-01'
     AND EXISTS (
         SELECT 1
         FROM inventory inv
         WHERE inv.inv_item_sk = i.i_item_sk
           AND inv.inv_quantity_on_hand > 0
     )
     AND NOT EXISTS (
         SELECT 1
         FROM store_returns sr
         WHERE sr.sr_customer_sk = c.c_customer_sk
           AND sr.sr_item_sk = i.i_item_sk
     )
   GROUP BY c.c_customer_id, i.i_item_id, i.i_item_sk
)
SELECT
   customer_id,
   item_id,
   total_sales,
   channel,
   sales_category,
   price_diff,
   ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_sales DESC) AS sales_rank
FROM union_sales
ORDER BY total_sales DESC
LIMIT 100
