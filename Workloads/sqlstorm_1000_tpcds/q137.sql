SELECT year,
       sales_channel,
       c.c_customer_id,
       sum(net_paid) AS total_paid,
       sum(net_profit) AS total_profit
FROM (
    SELECT d.d_year AS year,
           'web' AS sales_channel,
           ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           'store',
           ss.ss_customer_sk,
           ss.ss_net_paid,
           ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           'catalog',
           cs.cs_bill_customer_sk,
           cs.cs_net_paid,
           cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
) t
JOIN customer c ON t.customer_sk = c.c_customer_sk
WHERE year = 2000
GROUP BY year, sales_channel, c.c_customer_id
ORDER BY total_profit DESC
LIMIT 10
