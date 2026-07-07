WITH combined_sales AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_item_id AS i_item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        i_item_id,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM combined_sales
    GROUP BY i_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customer_count,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
JOIN items i ON s.i_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON s.i_item_id = r.i_item_id
ORDER BY s.total_revenue DESC
LIMIT 10
