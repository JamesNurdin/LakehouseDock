WITH web_sales_2022 AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk, c.c_customer_id
),
store_returns_2022 AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk, c.c_customer_id
)
SELECT ws.c_customer_id,
       ws.total_net_paid AS amount,
       'web_sales' AS source
FROM web_sales_2022 ws
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns_2022 sr
    WHERE sr.c_customer_sk = ws.c_customer_sk
)
UNION ALL
SELECT sr.c_customer_id,
       sr.total_return_amt AS amount,
       'store_returns' AS source
FROM store_returns_2022 sr
ORDER BY amount DESC
LIMIT 100
