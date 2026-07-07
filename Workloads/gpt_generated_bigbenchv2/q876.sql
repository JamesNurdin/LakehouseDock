WITH sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT
        CAST(NULL AS BIGINT) AS store_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity
    FROM web_sales ws
),

sales_agg AS (
    SELECT
        s.store_id,
        i.i_category,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * i.i_price) AS total_revenue
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY s.store_id, i.i_category
),

reviews_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    COALESCE(st.s_store_name, 'Web') AS store_name,
    s.i_category AS category,
    s.total_quantity,
    s.total_revenue,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
LEFT JOIN reviews_agg r ON s.i_category = r.i_category
LEFT JOIN stores st ON s.store_id = st.s_store_id
ORDER BY s.total_revenue DESC
LIMIT 20
