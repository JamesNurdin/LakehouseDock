WITH unified_sales AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id,
        i.i_price AS price
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        'Online' AS store_name,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        store_name,
        i_category_id,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS distinct_customers
    FROM unified_sales
    GROUP BY store_name, i_category_id, i_category_name
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
)
SELECT
    s.store_name,
    s.i_category_id,
    s.i_category_name,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customers,
    r.avg_rating,
    r.review_count
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.i_category_id = r.i_category_id
ORDER BY s.store_name, s.i_category_id
