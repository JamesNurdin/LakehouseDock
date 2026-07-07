WITH store_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_review_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0) AS total_quantity,
    COALESCE(sa.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(wa.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(sa.total_store_revenue, 0) + COALESCE(wa.total_web_revenue, 0) AS total_revenue,
    COALESCE(sa.distinct_store_customers, 0) + COALESCE(wa.distinct_web_customers, 0) AS distinct_customers,
    COALESCE(ra.review_count, 0) AS review_count,
    ra.avg_review_sentiment
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_revenue DESC
LIMIT 10
