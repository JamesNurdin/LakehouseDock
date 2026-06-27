WITH sales AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        i.i_category_id AS i_category_id,
        i.i_category_name AS i_category_name,
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id AS store_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_item_id AS i_item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        i.i_category_id AS i_category_id,
        i.i_category_name AS i_category_name,
        ws.ws_customer_id AS customer_id,
        NULL AS store_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
reviews_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.i_category_id,
    s.i_category_name,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.price * s.quantity) AS total_revenue,
    AVG(r.avg_rating) AS avg_item_rating,
    SUM(r.review_cnt) AS total_review_count,
    COUNT(DISTINCT s.customer_id) AS distinct_customer_count,
    COUNT(DISTINCT s.store_id) AS distinct_store_count
FROM sales s
LEFT JOIN reviews_agg r ON s.i_item_id = r.pr_item_id
JOIN customers c ON s.customer_id = c.c_customer_id
LEFT JOIN stores st ON s.store_id = st.s_store_id
GROUP BY s.i_category_id, s.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
