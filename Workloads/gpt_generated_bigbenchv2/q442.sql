WITH unified_sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id,
        i.i_price AS price,
        i.i_name AS i_name,
        i.i_category_id AS i_category_id,
        i.i_category_name AS i_category_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id,
        i.i_price AS price,
        i.i_name AS i_name,
        i.i_category_id AS i_category_id,
        i.i_category_name AS i_category_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),

sales_agg AS (
    SELECT
        item_id,
        i_name,
        i_category_id,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM unified_sales
    GROUP BY item_id, i_name, i_category_id, i_category_name
),

review_agg AS (
    SELECT
        i.i_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.item_id,
    s.i_name,
    s.i_category_name,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customer_count,
    r.avg_rating,
    r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.item_id = r.item_id
ORDER BY s.total_revenue DESC
LIMIT 10
