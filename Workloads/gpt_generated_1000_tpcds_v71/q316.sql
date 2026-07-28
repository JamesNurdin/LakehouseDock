WITH return_stats AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cr.cr_net_loss) AS total_amount,
        'return' AS source_type,
        CASE WHEN SUM(cr.cr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_returning_customer_sk ORDER BY SUM(cr.cr_net_loss) DESC) AS amount_rank,
        (
            SELECT AVG(cr2.cr_net_loss)
            FROM catalog_returns cr2
            WHERE cr2.cr_returning_customer_sk = cr.cr_returning_customer_sk
        ) AS avg_amount
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    GROUP BY cr.cr_returning_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(cr.cr_net_loss) > 1000
),
sales_stats AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_profit) AS total_amount,
        'sale' AS source_type,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS amount_rank,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
        ) AS avg_amount
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY cs.cs_bill_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(cs.cs_net_profit) > 2000
)
SELECT
    customer_sk,
    c_first_name,
    c_last_name,
    total_amount,
    source_type,
    amount_category,
    amount_rank,
    avg_amount
FROM (
    SELECT * FROM return_stats
    UNION ALL
    SELECT * FROM sales_stats
) combined
ORDER BY total_amount DESC
LIMIT 100
