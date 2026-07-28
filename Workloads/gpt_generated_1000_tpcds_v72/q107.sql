WITH catalog_profit AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450646 AND 2452167
    GROUP BY c.c_customer_id
    HAVING SUM(cs.cs_net_profit) > 1000
),
web_profit AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450646 AND 2452167
    GROUP BY c.c_customer_id
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT DISTINCT
    combined.customer_id,
    combined.total_profit,
    combined.profit_flag
FROM (
    SELECT * FROM catalog_profit
    UNION ALL
    SELECT * FROM web_profit
) AS combined
ORDER BY combined.total_profit DESC
LIMIT 100
