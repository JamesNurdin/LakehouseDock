WITH store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
online_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS online_quantity,
        SUM(ws.ws_quantity * i.i_price) AS online_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_reviews AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    scs.s_store_name,
    scs.i_category_name,
    scs.store_quantity,
    scs.store_revenue,
    COALESCE(ocs.online_quantity, 0) AS online_quantity,
    COALESCE(ocs.online_revenue, 0) AS online_revenue,
    COALESCE(cr.avg_rating, 0) AS avg_rating,
    COALESCE(cr.review_count, 0) AS review_count
FROM store_category_sales scs
LEFT JOIN online_category_sales ocs
    ON scs.i_category_id = ocs.i_category_id
LEFT JOIN category_reviews cr
    ON scs.i_category_id = cr.i_category_id
ORDER BY (scs.store_revenue + COALESCE(ocs.online_revenue, 0)) DESC
LIMIT 10
