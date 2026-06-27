WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ss.ss_quantity AS quantity,
        (i.i_price * ss.ss_quantity) AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ws.ws_quantity AS quantity,
        (i.i_price * ws.ws_quantity) AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_sales AS (
    SELECT
        i_category_id,
        i_category_name,
        SUM(revenue) AS total_revenue,
        SUM(quantity) AS total_quantity
    FROM item_sales
    GROUP BY i_category_id, i_category_name
),
item_reviews AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
category_reviews AS (
    SELECT
        i_category_id,
        i_category_name,
        AVG(avg_rating) AS category_avg_rating,
        SUM(review_count) AS category_review_count
    FROM item_reviews
    GROUP BY i_category_id, i_category_name
)
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.total_revenue,
    cs.total_quantity,
    cr.category_avg_rating,
    cr.category_review_count
FROM category_sales cs
JOIN category_reviews cr
    ON cs.i_category_id = cr.i_category_id
ORDER BY cs.total_revenue DESC
LIMIT 10
