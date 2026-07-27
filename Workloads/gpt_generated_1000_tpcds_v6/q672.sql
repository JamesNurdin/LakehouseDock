WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        MIN(ws.ws_web_site_sk) AS web_site_sk
    FROM
        customer c
        JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
            AND ss.ss_sold_date_sk = d.d_date_sk
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        c.c_first_sales_date_sk = 2452167
        AND d.d_year = 2000
        AND d.d_dow IN (1, 2, 3)
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        d.d_year
)
SELECT
    cs.c_customer_id,
    cs.d_year,
    cs.catalog_profit,
    cs.store_profit,
    cs.web_profit,
    (cs.catalog_profit + cs.store_profit + cs.web_profit) AS total_profit,
    CASE
        WHEN (cs.catalog_profit + cs.store_profit + cs.web_profit) > 10000 THEN 'High'
        WHEN (cs.catalog_profit + cs.store_profit + cs.web_profit) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    wsit.web_name,
    RANK() OVER (PARTITION BY cs.c_customer_id ORDER BY (cs.catalog_profit + cs.store_profit + cs.web_profit) DESC) AS profit_rank,
    (
        SELECT AVG(t.total_profit)
        FROM (
            SELECT SUM(cs_inner.cs_net_profit) AS total_profit
            FROM catalog_sales cs_inner
            GROUP BY cs_inner.cs_bill_customer_sk
        ) t
    ) AS avg_customer_profit
FROM
    customer_sales cs
    JOIN web_site wsit ON wsit.web_site_sk = cs.web_site_sk
WHERE
    wsit.web_class = 'Technology'
ORDER BY
    total_profit DESC
LIMIT 100
