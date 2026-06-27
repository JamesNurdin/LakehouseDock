WITH
    store_category_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    web_category_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    review_category_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            COUNT(pr.pr_review_id) AS review_count,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT
    COALESCE(sc.i_category_id, wc.i_category_id, rc.i_category_id) AS category_id,
    COALESCE(sc.i_category_name, wc.i_category_name, rc.i_category_name) AS category_name,
    COALESCE(sc.store_quantity, 0) AS store_quantity,
    COALESCE(sc.store_revenue, 0) AS store_revenue,
    COALESCE(sc.store_customer_count, 0) AS store_customer_count,
    COALESCE(wc.web_quantity, 0) AS web_quantity,
    COALESCE(wc.web_revenue, 0) AS web_revenue,
    COALESCE(wc.web_customer_count, 0) AS web_customer_count,
    COALESCE(rc.review_count, 0) AS review_count,
    rc.avg_rating
FROM store_category_agg sc
FULL OUTER JOIN web_category_agg wc
    ON sc.i_category_id = wc.i_category_id
FULL OUTER JOIN review_category_agg rc
    ON COALESCE(sc.i_category_id, wc.i_category_id) = rc.i_category_id
ORDER BY category_name
