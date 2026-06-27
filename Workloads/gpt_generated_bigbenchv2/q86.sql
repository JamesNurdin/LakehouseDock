WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_info AS (
    SELECT
        s.s_store_id,
        s.s_store_name
    FROM stores s
)
SELECT
    si.s_store_name,
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(ssa.store_quantity, 0) AS store_quantity,
    COALESCE(ssa.store_revenue, 0) AS store_revenue,
    COALESCE(ssa.store_distinct_customers, 0) AS store_distinct_customers,
    COALESCE(wsa.web_quantity, 0) AS web_quantity,
    COALESCE(wsa.web_revenue, 0) AS web_revenue,
    COALESCE(wsa.web_distinct_customers, 0) AS web_distinct_customers,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count,
    (COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0)) AS total_quantity,
    (COALESCE(ssa.store_revenue, 0) + COALESCE(wsa.web_revenue, 0)) AS total_revenue
FROM store_info si
JOIN store_sales_agg ssa ON si.s_store_id = ssa.ss_store_id
JOIN items i ON ssa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
ORDER BY total_revenue DESC
LIMIT 20
