WITH sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
item_sales AS (
    SELECT
        s.item_id,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * s.price) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales s
    GROUP BY s.item_id
),
item_details AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price
    FROM items i
),
item_ratings AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    d.i_category_id,
    d.i_category_name,
    SUM(s.total_quantity) AS total_quantity_sold,
    SUM(s.total_revenue) AS total_revenue,
    AVG(r.avg_rating) AS avg_category_rating,
    SUM(r.review_count) AS total_reviews,
    SUM(s.distinct_customers) AS total_distinct_customers
FROM item_sales s
JOIN item_details d ON d.i_item_id = s.item_id
LEFT JOIN item_ratings r ON r.pr_item_id = d.i_item_id
GROUP BY d.i_category_id, d.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
