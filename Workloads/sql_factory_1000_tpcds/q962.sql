WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2021
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
promo_activity AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY SUM(ss.ss_ext_discount_amt) DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2021 AND ss.ss_promo_sk IS NOT NULL
    GROUP BY ss.ss_customer_sk, ss.ss_promo_sk
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.total_profit,
    cs.unique_tickets,
    p.p_promo_name,
    pa.total_discount,
    CASE WHEN cs.total_profit / NULLIF(cs.total_sales,0) > 0.2 THEN 'HighMargin' ELSE 'LowMargin' END AS margin_category,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
FROM customer_sales cs
LEFT JOIN promo_activity pa ON cs.c_customer_sk = pa.ss_customer_sk AND pa.rn = 1
LEFT JOIN promotion p ON pa.ss_promo_sk = p.p_promo_sk
ORDER BY sales_rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
