WITH store_sales_2021 AS (
    SELECT 
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d 
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
catalog_sales_2021 AS (
    SELECT 
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d 
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_sales_2021 AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d 
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
all_sales AS (
    SELECT * FROM store_sales_2021
    UNION ALL
    SELECT * FROM catalog_sales_2021
    UNION ALL
    SELECT * FROM web_sales_2021
)
SELECT 
    c.c_customer_id,
    SUM(all_sales.net_paid) AS total_net_paid,
    SUM(all_sales.net_profit) AS total_net_profit,
    COUNT(*) AS total_transactions
FROM all_sales
JOIN customer c 
  ON all_sales.customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_net_profit DESC
LIMIT 10
