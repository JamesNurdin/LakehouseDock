WITH sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_customer_id AS customer_id,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_customer_id AS customer_id,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(s.quantity) AS total_units_sold,
        SUM(s.quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
sentiment_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.i_category_id,
    s.i_category,
    s.total_units_sold,
    s.total_revenue,
    s.distinct_customers,
    COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM sales_agg s
LEFT JOIN sentiment_agg r
    ON s.i_category_id = r.i_category_id
ORDER BY s.total_revenue DESC
LIMIT 10
