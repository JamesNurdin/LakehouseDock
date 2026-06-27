WITH store_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0)) AS total_quantity,
    SUM(COALESCE(sa.total_store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wa.total_web_quantity, 0)) AS total_web_quantity,
    SUM((COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0)) * i.i_price) AS total_revenue,
    COUNT(DISTINCT CASE WHEN sa.total_store_quantity IS NOT NULL THEN i.i_item_id END) AS distinct_items_sold_in_store,
    COUNT(DISTINCT CASE WHEN wa.total_web_quantity IS NOT NULL THEN i.i_item_id END) AS distinct_items_sold_online,
    AVG(COALESCE(ra.avg_rating, 0)) AS avg_rating,
    SUM(COALESCE(ra.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN store_agg sa ON sa.i_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity DESC
LIMIT 10
