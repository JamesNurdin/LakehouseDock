WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_item_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_item_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_name,
    ss_agg.i_category_name,
    ss_agg.i_item_id,
    i.i_name,
    ss_agg.total_store_quantity,
    ws_agg.total_web_quantity,
    ss_agg.total_store_revenue,
    ss_agg.distinct_store_customers + COALESCE(ws_agg.distinct_web_customers, 0) AS total_distinct_customers,
    rev_agg.avg_rating,
    rev_agg.review_count
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
JOIN items i ON ss_agg.i_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws_agg ON ss_agg.i_item_id = ws_agg.i_item_id
LEFT JOIN reviews_agg rev_agg ON ss_agg.i_item_id = rev_agg.i_item_id
ORDER BY ss_agg.total_store_quantity DESC
LIMIT 20
