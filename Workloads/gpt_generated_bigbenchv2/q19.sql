WITH
    store_sales_agg AS (
        SELECT
            s.s_store_id,
            s.s_store_name,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue,
            SUM(ss.ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss.ss_transaction_id) AS store_transactions
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue,
            SUM(ws.ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws.ws_transaction_id) AS web_transactions
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
    )
SELECT
    ss.s_store_name,
    ss.i_category_name,
    ss.store_revenue,
    ws.web_revenue,
    ss.store_quantity,
    ws.web_quantity,
    ss.store_transactions,
    ws.web_transactions,
    r.avg_rating,
    r.review_count
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
LEFT JOIN rating_agg r
    ON ss.i_category_id = r.i_category_id
ORDER BY ss.store_revenue DESC
