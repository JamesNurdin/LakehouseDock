WITH sales_filtered AS (
    SELECT DISTINCT
        s.s_manager,
        i.i_category,
        ss.ss_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_manager LIKE '%Smith%'
      AND regexp_like(i.i_item_desc, '[0-9]{3}')
      AND substr(s.s_store_name, 1, 5) = 'Store'
),
agg AS (
    SELECT
        s_manager,
        i_category,
        SUM(ss_net_paid) AS total_net_paid
    FROM sales_filtered
    GROUP BY s_manager, i_category
)
SELECT
    s_manager,
    i_category,
    total_net_paid,
    COUNT(*) OVER (PARTITION BY s_manager) AS categories_per_manager,
    ROW_NUMBER() OVER (PARTITION BY s_manager ORDER BY total_net_paid DESC) AS rank_in_manager
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
