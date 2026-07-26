WITH page_customer_sales AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_creation_date_sk,
        wp.wp_type,
        COUNT(DISTINCT wp.wp_customer_sk) AS visitors,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
        COUNT(DISTINCT ss.ss_store_sk) AS distinct_stores,
        MIN(ss.ss_sold_date_sk) AS first_sale_date_sk
    FROM web_page wp
    LEFT JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE wp.wp_type = 'article'
    GROUP BY wp.wp_web_page_sk, wp.wp_url, wp.wp_creation_date_sk, wp.wp_type
),
page_rankings AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
        SUM(total_net_profit) OVER (PARTITION BY wp_type ORDER BY wp_creation_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_type,
        CASE
            WHEN visitors > 800 THEN 'High Traffic'
            WHEN visitors BETWEEN 400 AND 800 THEN 'Medium Traffic'
            ELSE 'Low Traffic'
        END AS traffic_category
    FROM page_customer_sales
)
SELECT
    wp_web_page_sk,
    wp_url,
    wp_type,
    visitors,
    total_net_paid,
    total_net_profit,
    avg_discount,
    distinct_items_sold,
    distinct_stores,
    first_sale_date_sk,
    traffic_category,
    profit_rank,
    cumulative_profit_by_type
FROM page_rankings
WHERE total_net_profit > 0
ORDER BY profit_rank
LIMIT 20
