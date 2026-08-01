WITH date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
),
union_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        'sale' AS activity_type,
        SUM(cs.cs_net_paid) AS total_amount
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        'return' AS activity_type,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount
    FROM store_returns sr
    JOIN date_filter df ON sr.sr_returned_date_sk = df.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT DISTINCT
    ud.c_customer_sk,
    ud.c_first_name,
    ud.c_last_name,
    ud.activity_type,
    ud.total_amount,
    (
        SELECT ROUND(AVG(cs2.cs_net_profit), 2)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = ud.c_customer_sk
    ) AS avg_customer_profit
FROM union_data ud
WHERE ud.total_amount > (
    SELECT COALESCE(SUM(cs3.cs_net_paid), 0)
    FROM catalog_sales cs3
    WHERE cs3.cs_bill_customer_sk = ud.c_customer_sk
      AND cs3.cs_sold_date_sk = (SELECT MIN(d_date_sk) FROM date_filter)
)
ORDER BY ud.total_amount DESC
LIMIT 100
