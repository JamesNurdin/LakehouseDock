WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        i.i_category_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    LEFT JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_item_id, i.i_name, i.i_category, i.i_category_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    i.i_name,
    COALESCE(ssa.total_store_quantity, 0) + COALESCE(wsa.total_web_quantity, 0) AS total_quantity_sold,
    COALESCE(ssa.total_store_revenue, 0) + COALESCE(wsa.total_web_revenue, 0) AS total_revenue,
    COALESCE(ssa.distinct_store_customers, 0) + COALESCE(wsa.distinct_web_customers, 0) AS total_distinct_customers,
    COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 20
