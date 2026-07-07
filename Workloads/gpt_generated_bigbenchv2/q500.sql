WITH sales_summary AS (
    SELECT
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM items i
    LEFT JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    LEFT JOIN customers c_ss ON ss.ss_customer_id = c_ss.c_customer_id
    LEFT JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
    LEFT JOIN customers c_ws ON ws.ws_customer_id = c_ws.c_customer_id
    GROUP BY i.i_category
),
review_summary AS (
    SELECT
        i.i_category,
        AVG(CAST(pr.pr_sentiment AS double)) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    ss.i_category,
    ss.total_store_quantity,
    ss.total_web_quantity,
    ss.distinct_store_customers,
    ss.distinct_web_customers,
    rs.avg_sentiment,
    rs.review_count
FROM sales_summary ss
LEFT JOIN review_summary rs ON ss.i_category = rs.i_category
ORDER BY (ss.total_store_quantity + ss.total_web_quantity) DESC
LIMIT 10
