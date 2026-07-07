WITH store_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_review_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category,
    SUM(COALESCE(sa.total_store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wa.total_web_quantity, 0)) AS total_web_quantity,
    SUM(COALESCE(sa.distinct_store_customers, 0)) AS distinct_store_customers,
    SUM(COALESCE(wa.distinct_web_customers, 0)) AS distinct_web_customers,
    AVG(ra.avg_review_sentiment) AS avg_review_sentiment,
    SUM(COALESCE(ra.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
GROUP BY i.i_category
ORDER BY total_store_quantity DESC
LIMIT 10
