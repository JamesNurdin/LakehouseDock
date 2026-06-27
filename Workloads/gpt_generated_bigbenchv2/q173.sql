WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_id,
            s.s_store_name,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS total_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY ss.ss_store_id, s.s_store_name, i.i_category_id, i.i_category_name
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
    rating_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    all_customers AS (
        SELECT i.i_category_id, i.i_category_name, ss.ss_customer_id AS customer_id
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT i.i_category_id, i.i_category_name, ws.ws_customer_id AS customer_id
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    distinct_customers_agg AS (
        SELECT i_category_id, i_category_name, COUNT(DISTINCT customer_id) AS distinct_customers
        FROM all_customers
        GROUP BY i_category_id, i_category_name
    )
SELECT
    ssa.ss_store_id,
    ssa.s_store_name,
    ssa.i_category_id,
    ssa.i_category_name,
    ssa.total_quantity,
    ssa.total_revenue,
    COALESCE(wsa.web_quantity, 0) AS web_quantity,
    COALESCE(wsa.web_revenue, 0) AS web_revenue,
    r.avg_rating,
    r.review_count,
    dc.distinct_customers
FROM store_sales_agg ssa
LEFT JOIN web_sales_agg wsa
    ON ssa.i_category_id = wsa.i_category_id
   AND ssa.i_category_name = wsa.i_category_name
LEFT JOIN rating_agg r
    ON ssa.i_category_id = r.i_category_id
   AND ssa.i_category_name = r.i_category_name
LEFT JOIN distinct_customers_agg dc
    ON ssa.i_category_id = dc.i_category_id
   AND ssa.i_category_name = dc.i_category_name
ORDER BY ssa.total_revenue DESC
LIMIT 100
