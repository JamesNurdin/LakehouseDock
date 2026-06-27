WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers,
        SUM(COALESCE(ir.avg_rating, 0) * ss.ss_quantity) AS rating_quantity_product,
        SUM(ss.ss_quantity) AS rating_quantity_base
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
store_sales_final AS (
    SELECT
        ss_store_id,
        i_category_id,
        i_category_name,
        store_quantity,
        store_revenue,
        store_customers,
        rating_quantity_product,
        rating_quantity_base
    FROM store_sales_agg
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers,
        SUM(COALESCE(ir.avg_rating, 0) * ws.ws_quantity) AS rating_quantity_product,
        SUM(ws.ws_quantity) AS rating_quantity_base
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_final AS (
    SELECT
        i_category_id,
        i_category_name,
        web_quantity,
        web_revenue,
        web_customers,
        rating_quantity_product,
        rating_quantity_base
    FROM web_sales_agg
)
SELECT
    COALESCE(ssf.ss_store_id, -1) AS store_id,
    st.s_store_name,
    COALESCE(ssf.i_category_id, wsf.i_category_id) AS category_id,
    COALESCE(ssf.i_category_name, wsf.i_category_name) AS category_name,
    COALESCE(ssf.store_quantity, 0) AS store_quantity,
    COALESCE(wsf.web_quantity, 0) AS web_quantity,
    COALESCE(ssf.store_quantity, 0) + COALESCE(wsf.web_quantity, 0) AS total_quantity,
    COALESCE(ssf.store_revenue, 0) AS store_revenue,
    COALESCE(wsf.web_revenue, 0) AS web_revenue,
    COALESCE(ssf.store_revenue, 0) + COALESCE(wsf.web_revenue, 0) AS total_revenue,
    COALESCE(ssf.store_customers, 0) + COALESCE(wsf.web_customers, 0) AS total_customers,
    CASE
        WHEN (COALESCE(ssf.rating_quantity_base, 0) + COALESCE(wsf.rating_quantity_base, 0)) > 0 THEN
            (COALESCE(ssf.rating_quantity_product, 0) + COALESCE(wsf.rating_quantity_product, 0))
            / (COALESCE(ssf.rating_quantity_base, 0) + COALESCE(wsf.rating_quantity_base, 0))
        ELSE NULL
    END AS avg_rating
FROM store_sales_final ssf
FULL OUTER JOIN web_sales_final wsf
    ON ssf.i_category_id = wsf.i_category_id
    AND ssf.i_category_name = wsf.i_category_name
LEFT JOIN stores st
    ON ssf.ss_store_id = st.s_store_id
ORDER BY total_revenue DESC
LIMIT 100
