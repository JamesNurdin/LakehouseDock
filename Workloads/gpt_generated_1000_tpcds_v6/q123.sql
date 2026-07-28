WITH customers_with_returns AS (
    SELECT DISTINCT sr.sr_customer_sk AS cust_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    UNION
    SELECT DISTINCT wr.wr_refunded_customer_sk
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT combined.c_customer_id,
       combined.total_sales,
       combined.channel
FROM (
    SELECT c.c_customer_id,
           SUM(cs.cs_net_paid) AS total_sales,
           'Catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND EXISTS (
          SELECT 1
          FROM customers_with_returns cr
          WHERE cr.cust_sk = c.c_customer_sk
      )
    GROUP BY c.c_customer_id

    UNION ALL

    SELECT c.c_customer_id,
           SUM(ws.ws_net_paid) AS total_sales,
           'Web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND EXISTS (
          SELECT 1
          FROM customers_with_returns cr
          WHERE cr.cust_sk = c.c_customer_sk
      )
    GROUP BY c.c_customer_id
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 50
