WITH category_sales AS (
    SELECT
        i_category_name,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_quantity * i_price) AS total_revenue,
        COUNT(DISTINCT ws_customer_id) AS distinct_customers,
        COUNT(DISTINCT i_item_id) AS distinct_items
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY i_category_name
),
category_reviews AS (
    SELECT
        i_category_name,
        AVG(pr_rating) AS avg_rating,
        COUNT(pr_review_id) AS review_count
    FROM product_reviews
    JOIN items ON product_reviews.pr_item_id = items.i_item_id
    GROUP BY i_category_name
)
SELECT
    cs.i_category_name,
    cs.total_quantity,
    cs.total_revenue,
    cs.distinct_customers,
    cs.distinct_items,
    cr.avg_rating,
    cr.review_count
FROM category_sales cs
LEFT JOIN category_reviews cr
    ON cs.i_category_name = cr.i_category_name
ORDER BY cs.total_revenue DESC
LIMIT 20
