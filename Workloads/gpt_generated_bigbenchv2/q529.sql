WITH store_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_qty,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_item_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_qty,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_item_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT
    i.i_category,
    i.i_name,
    i.i_price,
    COALESCE(sa.total_store_qty, 0) AS total_store_quantity,
    COALESCE(wa.total_web_qty, 0) AS total_web_quantity,
    COALESCE(sa.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(wa.distinct_web_customers, 0) AS distinct_web_customers,
    ra.avg_sentiment,
    ra.review_count
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
ORDER BY i.i_category, i.i_name
