WITH unified_sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_price,
        ss.ss_quantity AS store_quantity,
        NULL AS web_quantity,
        c.c_customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    UNION ALL
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_price,
        NULL AS store_quantity,
        ws.ws_quantity AS web_quantity,
        c.c_customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
category_reviews AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    us.i_category,
    SUM(COALESCE(us.store_quantity, 0) + COALESCE(us.web_quantity, 0)) AS total_quantity,
    SUM((COALESCE(us.store_quantity, 0) + COALESCE(us.web_quantity, 0)) * us.i_price) AS total_revenue,
    COUNT(DISTINCT us.c_customer_id) AS distinct_customers,
    cr.avg_sentiment,
    cr.review_count
FROM unified_sales us
LEFT JOIN category_reviews cr ON cr.i_category = us.i_category
GROUP BY us.i_category, cr.avg_sentiment, cr.review_count
ORDER BY total_revenue DESC
