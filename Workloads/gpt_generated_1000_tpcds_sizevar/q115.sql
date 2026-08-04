WITH web_no_return AS (
   SELECT DISTINCT c.c_customer_id AS customer_id
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND hd.hd_vehicle_count > 0
     AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = ws.ws_bill_customer_sk
          AND sr.sr_returned_date_sk = ws.ws_sold_date_sk
     )
),
return_no_web AS (
   SELECT DISTINCT c.c_customer_id AS customer_id
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND hd.hd_vehicle_count > 0
     AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = sr.sr_customer_sk
          AND ws.ws_sold_date_sk = sr.sr_returned_date_sk
     )
)
SELECT customer_id
FROM web_no_return
INTERSECT
SELECT customer_id
FROM return_no_web
ORDER BY customer_id
