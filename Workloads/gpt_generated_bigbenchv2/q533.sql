WITH
    item_ratings AS (
        SELECT
            i.i_item_id,
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count,
            AVG(i.i_price) AS avg_price
        FROM product_reviews pr
        JOIN items i
            ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
    ),
    store_sales_agg AS (
        SELECT
            i.i_item_id,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count,
            COUNT(DISTINCT ss.ss_store_id) AS store_count
        FROM store_sales ss
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        JOIN customers c
            ON ss.ss_customer_id = c.c_customer_id
        JOIN stores s
            ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_id,
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
        FROM web_sales ws
        JOIN items i
            ON ws.ws_item_id = i.i_item_id
        JOIN customers c
            ON ws.ws_customer_id = c.c_customer_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
    )
SELECT
    ir.i_item_id,
    ir.i_category_id,
    ir.i_category_name,
    ir.avg_rating,
    ir.review_count,
    ir.avg_price,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_customer_count, 0) AS store_customer_count,
    COALESCE(ws.web_customer_count, 0) AS web_customer_count,
    COALESCE(ss.store_customer_count, 0) + COALESCE(ws.web_customer_count, 0) AS total_customer_count
FROM item_ratings ir
LEFT JOIN store_sales_agg ss
    ON ir.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws
    ON ir.i_item_id = ws.i_item_id
ORDER BY total_quantity DESC
LIMIT 100
