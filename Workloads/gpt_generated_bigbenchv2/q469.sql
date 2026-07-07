WITH
store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_item_id, i.i_name, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_item_id, i.i_name, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_revenue, 0) AS store_revenue,
    COALESCE(ws.web_revenue, 0) AS web_revenue,
    COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
    COALESCE(r.avg_sentiment, NULL) AS avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
