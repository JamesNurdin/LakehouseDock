WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_id,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS total_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            CAST(-1 AS BIGINT) AS ss_store_id,
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    sales_combined AS (
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM web_sales_agg
    ),
    sales_by_store_category AS (
        SELECT
            sc.ss_store_id,
            sc.i_category_id,
            sc.i_category_name,
            SUM(sc.total_quantity) AS total_quantity
        FROM sales_combined sc
        GROUP BY sc.ss_store_id, sc.i_category_id, sc.i_category_name
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
        HAVING COUNT(pr.pr_review_id) >= 5
    )
SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    sbc.i_category_name,
    sbc.total_quantity,
    r.avg_rating,
    r.review_count
FROM sales_by_store_category sbc
LEFT JOIN stores s ON sbc.ss_store_id = s.s_store_id
LEFT JOIN rating_agg r ON sbc.i_category_id = r.i_category_id
ORDER BY sbc.total_quantity DESC
LIMIT 100
