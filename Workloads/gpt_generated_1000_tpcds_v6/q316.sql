WITH store_ret AS (
   SELECT
      ca.ca_state AS state,
      sr.sr_return_amt AS amount,
      sr.sr_returned_date_sk AS date_sk,
      SUM(sr.sr_return_amt) OVER (PARTITION BY ca.ca_state ORDER BY sr.sr_returned_date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amount
   FROM store_returns sr
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE sr.sr_return_amt > 100
),
web_sales_amt AS (
   SELECT
      ca.ca_state AS state,
      ws.ws_net_paid AS amount,
      ws.ws_sold_date_sk AS date_sk,
      SUM(ws.ws_net_paid) OVER (PARTITION BY ca.ca_state ORDER BY ws.ws_sold_date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amount
   FROM web_sales ws
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE ws.ws_net_paid > 200
)
SELECT state,
       amount,
       date_sk,
       cum_amount
FROM store_ret
UNION ALL
SELECT state,
       amount,
       date_sk,
       cum_amount
FROM web_sales_amt
ORDER BY state, date_sk
LIMIT 100
