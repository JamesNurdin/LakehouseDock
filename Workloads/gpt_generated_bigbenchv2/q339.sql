WITH sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        i.i_price,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        i.i_price,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        i_category_id,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(quantity * i_price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS distinct_customers
    FROM sales
    GROUP BY i_category_id, i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
items_agg AS (
    SELECT
        i_category_id,
        i_category_name,
        COUNT(DISTINCT i_item_id) AS distinct_items
    FROM items
    GROUP BY i_category_id, i_category_name
)
SELECT
    s.i_category_id AS category_id,
    s.i_category_name AS category_name,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customers,
    i.distinct_items,
    r.avg_rating,
    r.review_count
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.i_category_id = r.i_category_id
LEFT JOIN items_agg i
    ON s.i_category_id = i.i_category_id
ORDER BY s.total_revenue DESC
LIMIT 10
