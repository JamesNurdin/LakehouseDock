WITH sales AS (
    SELECT
        'store' AS src,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        CAST(NULL AS integer) AS rating,
        CAST(NULL AS bigint) AS review_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        'web' AS src,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        CAST(NULL AS integer) AS rating,
        CAST(NULL AS bigint) AS review_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id

    UNION ALL

    SELECT
        'review' AS src,
        i.i_category_name,
        0 AS quantity,
        CAST(0 AS decimal(7,2)) AS revenue,
        pr.pr_rating AS rating,
        pr.pr_review_id AS review_id
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
)
SELECT
    i_category_name,
    SUM(CASE WHEN src = 'store' THEN quantity END) AS total_store_quantity,
    SUM(CASE WHEN src = 'store' THEN revenue END) AS total_store_revenue,
    SUM(CASE WHEN src = 'web' THEN quantity END) AS total_web_quantity,
    SUM(CASE WHEN src = 'web' THEN revenue END) AS total_web_revenue,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    AVG(rating) AS avg_rating,
    COUNT(review_id) AS review_count
FROM sales
GROUP BY i_category_name
ORDER BY total_revenue DESC
LIMIT 100
