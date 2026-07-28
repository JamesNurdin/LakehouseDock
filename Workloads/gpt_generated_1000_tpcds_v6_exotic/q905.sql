WITH catalog AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           d.d_year,
           SUM(cs.cs_net_paid) AS total_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND d.d_year = 2001
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
web AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           d.d_year,
           SUM(ws.ws_net_paid) AS total_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND d.d_year = 2001
    GROUP BY ws.ws_bill_customer_sk, d.d_year
)
SELECT DISTINCT customer_sk,
       d_year,
       total_paid
FROM (
    SELECT customer_sk, d_year, total_paid FROM catalog
    UNION ALL
    SELECT customer_sk, d_year, total_paid FROM web
) AS combined
ORDER BY total_paid DESC
LIMIT 100
