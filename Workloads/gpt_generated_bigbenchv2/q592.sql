WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
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
    s.s_store_name,
    sa.i_category,
    sa.total_quantity,
    sa.total_revenue,
    ws.web_quantity,
    ws.web_revenue,
    rv.avg_sentiment,
    rv.review_count,
    sa.distinct_customers AS store_distinct_customers,
    ws.web_distinct_customers
FROM store_sales_agg sa
JOIN stores s ON sa.store_id = s.s_store_id
LEFT JOIN web_sales_agg ws ON sa.i_category_id = ws.i_category_id
LEFT JOIN review_agg rv ON sa.i_category_id = rv.i_category_id
ORDER BY sa.total_revenue DESC
LIMIT 10
