WITH customer_profit AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS total_transactions
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
promo_counts AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        COUNT(*) AS promo_count
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ss.ss_customer_sk, ss.ss_promo_sk
),
promo_usage AS (
    SELECT
        pc.ss_customer_sk,
        pc.ss_promo_sk,
        pc.promo_count,
        ROW_NUMBER() OVER (PARTITION BY pc.ss_customer_sk ORDER BY pc.promo_count DESC) AS rn
    FROM promo_counts pc
)
SELECT
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    cp.total_net_profit,
    cp.total_sales,
    cp.total_transactions,
    p.p_promo_name,
    CASE
        WHEN cp.total_net_profit > 100000 THEN 'VIP'
        ELSE 'Regular'
    END AS customer_segment,
    RANK() OVER (ORDER BY cp.total_net_profit DESC) AS profit_rank
FROM customer_profit cp
LEFT JOIN promo_usage pu
    ON cp.c_customer_sk = pu.ss_customer_sk
    AND pu.rn = 1
LEFT JOIN promotion p
    ON pu.ss_promo_sk = p.p_promo_sk
ORDER BY profit_rank
LIMIT 10
