WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * i.i_price) AS total_revenue
    FROM (
        SELECT ss.ss_item_id AS item_id, ss.ss_quantity AS quantity
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_id AS item_id, ws.ws_quantity AS quantity
        FROM web_sales ws
    ) s
    JOIN items i
        ON s.item_id = i.i_item_id
    GROUP BY
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price
),
item_reviews AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i_sales.i_category_id AS category_id,
    i_sales.i_category_name AS category_name,
    SUM(i_sales.total_quantity) AS category_total_quantity,
    SUM(i_sales.total_revenue) AS category_total_revenue,
    AVG(i_reviews.avg_rating) AS category_avg_rating,
    SUM(i_reviews.review_count) AS category_review_count
FROM item_sales i_sales
LEFT JOIN item_reviews i_reviews
    ON i_sales.i_item_id = i_reviews.i_item_id
GROUP BY
    i_sales.i_category_id,
    i_sales.i_category_name
ORDER BY
    category_total_revenue DESC
LIMIT 10
