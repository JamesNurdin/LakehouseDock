WITH customer_store_sales AS (
    SELECT
        c.c_customer_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS store_net_paid
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, ss.ss_store_sk
),
customer_top_store AS (
    SELECT
        c_customer_sk,
        ss_store_sk,
        store_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY store_net_paid DESC) AS rn
    FROM customer_store_sales
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_store_sk) AS distinct_stores,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
        MIN(ss.ss_sold_date_sk) AS first_purchase_date,
        MAX(ss.ss_sold_date_sk) AS last_purchase_date
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
),
customer_ltv AS (
    SELECT
        cs.*,
        ts.ss_store_sk AS top_store_sk,
        s.s_store_name AS top_store_name,
        cs.total_net_paid * (1 + COALESCE(cs.total_net_profit / NULLIF(cs.total_net_paid, 0), 0)) AS ltv_estimate,
        CASE
            WHEN cs.total_net_paid > 50000 THEN 'VIP'
            WHEN cs.total_net_paid > 20000 THEN 'Premium'
            WHEN cs.total_net_paid > 5000 THEN 'Regular'
            ELSE 'Occasional'
        END AS customer_segment
    FROM customer_sales cs
    LEFT JOIN customer_top_store ts ON cs.c_customer_sk = ts.c_customer_sk AND ts.rn = 1
    LEFT JOIN store s ON ts.ss_store_sk = s.s_store_sk
)
SELECT
    c_customer_sk,
    c_customer_id,
    c_first_name,
    c_last_name,
    total_net_paid,
    total_net_profit,
    avg_discount,
    distinct_stores,
    distinct_web_pages,
    top_store_name,
    ltv_estimate,
    customer_segment,
    ROW_NUMBER() OVER (ORDER BY ltv_estimate DESC) AS ltv_rank,
    SUM(total_net_paid) OVER (ORDER BY first_purchase_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_paid_to_date
FROM customer_ltv
WHERE distinct_stores > 0
ORDER BY ltv_rank
LIMIT 15
