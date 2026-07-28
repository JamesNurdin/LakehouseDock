WITH catalog_sales_cte AS (
        SELECT
            cs.cs_bill_customer_sk AS customer_sk,
            'catalog' AS channel,
            SUM(cs.cs_net_profit) AS profit,
            d.d_year
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY cs.cs_bill_customer_sk, d.d_year
        HAVING SUM(cs.cs_net_profit) > 0
    ),
    web_sales_cte AS (
        SELECT
            ws.ws_bill_customer_sk AS customer_sk,
            'web' AS channel,
            SUM(ws.ws_net_profit) AS profit,
            d.d_year
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY ws.ws_bill_customer_sk, d.d_year
        HAVING SUM(ws.ws_net_profit) > 0
    ),
    combined AS (
        SELECT customer_sk, channel, profit, d_year FROM catalog_sales_cte
        UNION ALL
        SELECT customer_sk, channel, profit, d_year FROM web_sales_cte
    )
SELECT DISTINCT
    c.c_customer_id AS customer_id,
    comb.channel,
    comb.profit,
    comb.d_year,
    RANK() OVER (PARTITION BY comb.d_year ORDER BY comb.profit DESC) AS profit_rank
FROM combined comb
JOIN customer c ON comb.customer_sk = c.c_customer_sk
WHERE comb.d_year BETWEEN 2001 AND 2002
ORDER BY comb.d_year, profit_rank
LIMIT 100
