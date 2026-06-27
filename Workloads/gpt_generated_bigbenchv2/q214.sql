WITH sales_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_quantity * i.i_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_item_id) AS distinct_items_sold
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count,
        COUNT(DISTINCT pr.pr_item_id) AS distinct_items_reviewed
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.i_category_id,
    s.i_category_name,
    s.total_quantity_sold,
    s.total_sales_amount,
    s.distinct_items_sold,
    r.avg_rating,
    r.review_count,
    r.distinct_items_reviewed
FROM sales_by_category s
LEFT JOIN reviews_by_category r
    ON s.i_category_id = r.i_category_id
ORDER BY s.total_sales_amount DESC
LIMIT 20
