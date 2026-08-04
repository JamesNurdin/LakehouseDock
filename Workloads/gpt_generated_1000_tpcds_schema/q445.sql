WITH store_data AS (
   SELECT DISTINCT ss.ss_customer_sk AS cust_id,
                   i.i_category AS cat
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2020
     AND ss.ss_net_profit > 0
     AND EXISTS (
         SELECT 1
         FROM store_returns sr
         WHERE sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_return_amt > 0
     )
),
web_data AS (
   SELECT DISTINCT ws.ws_bill_customer_sk AS cust_id,
                   i.i_category AS cat
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2020
     AND ws.ws_net_paid > 0
     AND EXISTS (
         SELECT 1
         FROM web_returns wr
         WHERE wr.wr_order_number = ws.ws_order_number
           AND wr.wr_return_amt > 0
     )
)
SELECT
    i.cust_id,
    i.cat,
    (
        SELECT MAX(it.i_current_price)
        FROM item it
        WHERE it.i_category = i.cat
    ) AS max_category_price
FROM (
    SELECT cust_id, cat FROM store_data
    INTERSECT
    SELECT cust_id, cat FROM web_data
) AS i
ORDER BY i.cat, i.cust_id
OFFSET 0 ROWS
LIMIT 100
