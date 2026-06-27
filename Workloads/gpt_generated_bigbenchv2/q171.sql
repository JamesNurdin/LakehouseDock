WITH store_sales_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category_name, ss.ss_store_id, s.s_store_name
),
store_sales_agg AS (
    SELECT
        i_category_id,
        i_category_name,
        SUM(total_quantity) AS store_quantity,
        SUM(total_revenue) AS store_revenue
    FROM store_sales_by_category
    GROUP BY i_category_id, i_category_name
),
store_top AS (
    SELECT
        i_category_id,
        i_category_name,
        s_store_name,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY total_quantity DESC) AS rn
    FROM store_sales_by_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    ca.i_category_id,
    ca.i_category_name,
    COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
    COALESCE(ssa.store_revenue, 0) + COALESCE(wsa.web_revenue, 0) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    st.s_store_name AS top_store_name,
    st.total_quantity AS top_store_quantity
FROM (
    SELECT DISTINCT i_category_id, i_category_name
    FROM items
) ca
LEFT JOIN store_sales_agg ssa ON ca.i_category_id = ssa.i_category_id
LEFT JOIN web_sales_agg wsa ON ca.i_category_id = wsa.i_category_id
LEFT JOIN reviews_agg ra ON ca.i_category_id = ra.i_category_id
LEFT JOIN (
    SELECT i_category_id, i_category_name, s_store_name, total_quantity
    FROM store_top
    WHERE rn = 1
) st ON ca.i_category_id = st.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
