WITH combined_sales AS (
    SELECT c.c_customer_id,
           d.d_year,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT c.c_customer_id,
           d.d_year,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
), aggregated AS (
    SELECT c_customer_id,
           SUM(profit) AS total_profit
    FROM combined_sales
    GROUP BY c_customer_id
)
SELECT DISTINCT c_customer_id,
                total_profit
FROM aggregated
WHERE total_profit > 1000
ORDER BY total_profit DESC
LIMIT 100
