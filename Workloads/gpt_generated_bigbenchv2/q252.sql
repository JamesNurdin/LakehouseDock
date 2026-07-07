WITH store_sales_cte AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        s.s_store_name AS store_name
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_cte AS (
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        'Online' AS store_name
    FROM web_sales ws
),
combined_sales AS (
    SELECT item_id, quantity, store_name FROM store_sales_cte
    UNION ALL
    SELECT item_id, quantity, store_name FROM web_sales_cte
),
sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        cs.store_name,
        SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category, cs.store_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.i_category,
    s.store_name,
    s.total_quantity,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_category_id = r.i_category_id
ORDER BY s.i_category, s.store_name
