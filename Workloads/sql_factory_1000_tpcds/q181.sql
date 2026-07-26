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
        COUNT(DISTINCT ss.ss_store_sk) AS distinct_stores
    FROM web_page wp
    LEFT JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY wp.wp_web_page_sk, wp.wp_url, wp.wp_creation_date_sk, wp.wp_type
),
page_rankings AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank,
        SUM(total_net_paid) OVER (ORDER BY wp_creation_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
        CASE
            WHEN visitors > 1000 THEN 'High Traffic'
            WHEN visitors BETWEEN 500 AND 1000 THEN 'Medium Traffic'
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
    traffic_category,
    net_paid_rank,
    cumulative_net_paid
FROM page_rankings
WHERE total_net_paid > 0
ORDER BY net_paid_rank
LIMIT 25
