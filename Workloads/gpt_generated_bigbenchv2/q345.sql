WITH sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        i.i_category_id,
        i.i_category_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    WHERE i.i_price > 20

    UNION ALL

    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        i.i_category_id,
        i.i_category_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    WHERE i.i_price > 20
),

sales_agg AS (
    SELECT
        item_id,
        i_category_id,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue
    FROM sales
    GROUP BY item_id, i_category_id, i_category_name
),

reviews_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
)
SELECT
    s.i_category_id AS category_id,
    s.i_category_name AS category_name,
    SUM(s.total_quantity) AS total_quantity,
    SUM(s.total_revenue) AS total_revenue,
    AVG(r.avg_rating) AS avg_rating,
    SUM(r.review_count) AS total_reviews
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.item_id = r.item_id
GROUP BY s.i_category_id, s.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
