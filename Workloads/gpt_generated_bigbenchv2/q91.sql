WITH store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity
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
        AVG(i.i_price) AS avg_price
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    scs.s_store_name,
    scs.i_category_name,
    scs.total_store_quantity,
    COALESCE(wcs.total_web_quantity, 0) AS total_web_quantity,
    cr.avg_rating,
    cr.avg_price
FROM store_category_sales scs
LEFT JOIN web_category_sales wcs
    ON scs.i_category_id = wcs.i_category_id
LEFT JOIN category_reviews cr
    ON scs.i_category_id = cr.i_category_id
ORDER BY scs.s_store_name, scs.i_category_name
