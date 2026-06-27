WITH sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        s.s_store_name AS store_name,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id

    UNION ALL

    SELECT
        NULL AS store_id,
        'Online' AS store_name,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        store_name,
        category_id,
        category_name,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue
    FROM sales
    GROUP BY store_name, category_id, category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.store_name,
    s.category_name,
    s.total_quantity,
    s.total_revenue,
    r.avg_rating,
    r.review_count
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.category_id = r.category_id
ORDER BY s.store_name, s.total_quantity DESC
