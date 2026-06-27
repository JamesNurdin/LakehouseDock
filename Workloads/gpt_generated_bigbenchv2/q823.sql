WITH item_reviews AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
    FROM items i
    JOIN web_sales ws
        ON ws.ws_item_id = i.i_item_id
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
category_agg AS (
    SELECT
        s.i_category_id,
        s.i_category_name,
        SUM(s.total_quantity) AS category_quantity,
        SUM(s.total_revenue) AS category_revenue,
        AVG(r.avg_rating) AS category_avg_rating,
        SUM(r.review_count) AS category_review_count,
        COUNT(DISTINCT s.i_item_id) AS distinct_items,
        SUM(s.distinct_customers) AS category_distinct_customers
    FROM item_sales s
    LEFT JOIN item_reviews r
        ON r.i_item_id = s.i_item_id
    GROUP BY s.i_category_id, s.i_category_name
)
SELECT
    i_category_id,
    i_category_name,
    category_quantity,
    category_revenue,
    category_avg_rating,
    category_review_count,
    distinct_items,
    category_distinct_customers
FROM category_agg
ORDER BY category_revenue DESC
LIMIT 10
