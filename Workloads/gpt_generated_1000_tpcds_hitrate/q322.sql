WITH web_sales_filtered AS (
   SELECT
     ws.ws_order_number AS order_number,
     ws.ws_sold_date_sk AS sold_date_sk,
     ws.ws_item_sk AS item_sk,
     i.i_item_id AS item_id,
     ws.ws_quantity AS quantity,
     ws.ws_net_paid AS net_amount,
     CASE WHEN ws.ws_quantity > 5 THEN 'Bulk' ELSE 'Single' END AS purchase_type,
     ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid DESC) AS rank,
     'Web' AS source
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE ws.ws_net_paid > 0
     AND NOT EXISTS (
       SELECT 1
       FROM store_returns sr
       WHERE sr.sr_item_sk = ws.ws_item_sk
         AND sr.sr_returned_date_sk = ws.ws_sold_date_sk
     )
),
store_returns_filtered AS (
   SELECT
     sr.sr_ticket_number AS order_number,
     sr.sr_returned_date_sk AS sold_date_sk,
     sr.sr_item_sk AS item_sk,
     i.i_item_id AS item_id,
     sr.sr_return_quantity AS quantity,
     -sr.sr_net_loss AS net_amount,
     CASE WHEN sr.sr_return_quantity > 3 THEN 'Large Return' ELSE 'Small Return' END AS purchase_type,
     ROW_NUMBER() OVER (PARTITION BY sr.sr_store_sk ORDER BY -sr.sr_net_loss DESC) AS rank,
     'Store' AS source
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE sr.sr_net_loss > 0
)
SELECT
  order_number,
  sold_date_sk,
  item_sk,
  item_id,
  quantity,
  net_amount,
  purchase_type,
  rank,
  source
FROM (
  SELECT order_number, sold_date_sk, item_sk, item_id, quantity, net_amount, purchase_type, rank, source
  FROM web_sales_filtered
  UNION ALL
  SELECT order_number, sold_date_sk, item_sk, item_id, quantity, net_amount, purchase_type, rank, source
  FROM store_returns_filtered
) AS combined
ORDER BY source, rank
LIMIT 100
