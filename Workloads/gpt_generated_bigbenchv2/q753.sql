WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name, s.s_store_id, s.s_store_name
),
store_top_store AS (
    SELECT i_item_id, s_store_name, store_revenue
    FROM (
        SELECT
            i_item_id,
            s_store_name,
            store_revenue,
            ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY store_revenue DESC) AS rn
        FROM store_sales_agg
    ) t
    WHERE rn = 1
),
store_agg AS (
    SELECT
        i_item_id,
        SUM(store_quantity) AS total_store_quantity,
        SUM(store_revenue) AS total_store_revenue,
        SUM(store_customer_cnt) AS total_store_customers
    FROM store_sales_agg
    GROUP BY i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.total_store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(sa.total_store_customers, 0) + COALESCE(wa.web_customer_cnt, 0) AS total_customers,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_cnt, 0) AS review_cnt,
    COALESCE(ts.s_store_name, 'N/A') AS top_store_name
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
LEFT JOIN store_top_store ts ON i.i_item_id = ts.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
