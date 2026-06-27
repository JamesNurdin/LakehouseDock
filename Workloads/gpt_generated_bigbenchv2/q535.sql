WITH sales_by_item AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS unique_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_by_item AS (
    SELECT
        pr.pr_item_id AS item_id,
        SUM(pr.pr_rating) AS sum_rating,
        COUNT(pr.pr_rating) AS rating_count,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(s.total_revenue), 0) AS total_sales_revenue,
    SUM(r.sum_rating) / NULLIF(SUM(r.rating_count), 0) AS average_rating,
    COALESCE(SUM(r.review_count), 0) AS total_review_count,
    COALESCE(SUM(s.unique_customers), 0) AS total_unique_customers,
    AVG(i.i_price - i.i_comp_price) AS average_price_margin
FROM items i
LEFT JOIN sales_by_item s
    ON s.item_id = i.i_item_id
LEFT JOIN reviews_by_item r
    ON r.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_sales_revenue DESC
LIMIT 10
