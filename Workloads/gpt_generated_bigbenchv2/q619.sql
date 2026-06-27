WITH
    store_sales_agg AS (
        SELECT
            s.s_store_id,
            s.s_store_name,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        JOIN stores s
            ON ss.ss_store_id = s.s_store_id
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        GROUP BY
            s.s_store_id,
            s.s_store_name,
            i.i_category_id,
            i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_quantity
        FROM web_sales ws
        JOIN items i
            ON ws.ws_item_id = i.i_item_id
        GROUP BY
            i.i_category_id,
            i.i_category_name
    ),
    reviews_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i
            ON pr.pr_item_id = i.i_item_id
        GROUP BY
            i.i_category_id,
            i.i_category_name
    )
SELECT
    ss.s_store_name,
    ss.i_category_name,
    ss.store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(rv.avg_rating, 0) AS avg_rating,
    COALESCE(rv.review_count, 0) AS review_count,
    (ss.store_quantity + COALESCE(ws.web_quantity, 0)) AS total_quantity
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
LEFT JOIN reviews_agg rv
    ON ss.i_category_id = rv.i_category_id
ORDER BY total_quantity DESC
