WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_item_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_item_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_name
),
product_reviews_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_customers_agg AS (
    SELECT
        ss.ss_store_id,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_name,
    COALESCE(ssa.i_category_name, wsa.i_category_name) AS category_name,
    COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
    COALESCE(ssa.store_revenue, 0) + COALESCE(wsa.web_revenue, 0) AS total_revenue,
    pra.avg_rating AS avg_item_rating,
    COALESCE(pra.review_count, 0) AS review_count,
    COALESCE(sca.distinct_customers, 0) AS distinct_customers
FROM store_sales_agg ssa
FULL OUTER JOIN web_sales_agg wsa
    ON ssa.i_item_id = wsa.i_item_id
LEFT JOIN product_reviews_agg pra
    ON COALESCE(ssa.i_item_id, wsa.i_item_id) = pra.pr_item_id
LEFT JOIN stores s
    ON ssa.ss_store_id = s.s_store_id
LEFT JOIN store_customers_agg sca
    ON ssa.ss_store_id = sca.ss_store_id
ORDER BY total_revenue DESC
LIMIT 20
