WITH sales_date AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 1999
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        'Catalog' AS channel,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(*) AS orders
    FROM catalog_sales cs
    JOIN sales_date sd ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 0
    GROUP BY cs.cs_bill_customer_sk, c.c_first_name, c.c_last_name
),
store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        'Store' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS orders
    FROM store_sales ss
    JOIN sales_date sd ON ss.ss_sold_date_sk = sd.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = ss.ss_customer_sk
          AND cs2.cs_sold_date_sk = sd.d_date_sk
    )
    GROUP BY ss.ss_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    customer_sk,
    c_first_name,
    c_last_name,
    channel,
    total_net_paid,
    orders,
    RANK() OVER (PARTITION BY channel ORDER BY total_net_paid DESC) AS sales_rank
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
