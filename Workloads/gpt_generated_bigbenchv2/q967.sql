WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price, i.i_comp_price
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(i.i_price * ws.ws_quantity) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price, i.i_comp_price
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name
)
SELECT
    i.i_category_name,
    i.i_item_id,
    i.i_name,
    COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(ssa.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wsa.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(ssa.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(wsa.distinct_web_customers, 0) AS distinct_web_customers,
    rag.avg_rating,
    rag.review_count,
    (COALESCE(ssa.total_store_quantity, 0) + COALESCE(wsa.total_web_quantity, 0)) AS total_quantity,
    (COALESCE(ssa.total_store_revenue, 0) + COALESCE(wsa.total_web_revenue, 0)) AS total_revenue
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN reviews_agg rag ON i.i_item_id = rag.i_item_id
WHERE (COALESCE(ssa.total_store_quantity, 0) + COALESCE(wsa.total_web_quantity, 0)) > 0
ORDER BY total_revenue DESC
LIMIT 100
