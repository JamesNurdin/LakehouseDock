WITH promo_store_metrics AS (
    SELECT
        ss.ss_promo_sk,
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    GROUP BY ss.ss_promo_sk, s.s_store_sk, s.s_store_name
),
promo_rankings AS (
    SELECT
        ss_promo_sk,
        s_store_sk,
        s_store_name,
        total_sales_price,
        total_profit,
        distinct_customers,
        distinct_web_pages,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY total_profit DESC) AS profit_rank_in_store,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS global_profit_rank
    FROM promo_store_metrics
)
SELECT
    ss_promo_sk AS promo_id,
    s_store_name,
    total_sales_price,
    total_profit,
    distinct_customers,
    distinct_web_pages,
    profit_rank_in_store,
    global_profit_rank,
    CASE
        WHEN total_profit > 50000 THEN 'High'
        WHEN total_profit > 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM promo_rankings
WHERE profit_rank_in_store <= 3
ORDER BY s_store_name, profit_rank_in_store
