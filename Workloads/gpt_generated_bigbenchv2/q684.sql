WITH category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
store_category_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name
),
web_category_sales AS (
    SELECT
        NULL AS ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
combined_category_sales AS (
    SELECT
        COALESCE(scs.ss_store_id, wcs.ss_store_id) AS store_id,
        COALESCE(s.s_store_name, 'Web') AS store_name,
        COALESCE(scs.i_category_id, wcs.i_category_id) AS category_id,
        COALESCE(scs.i_category_name, wcs.i_category_name) AS category_name,
        COALESCE(scs.store_quantity, 0) + COALESCE(wcs.web_quantity, 0) AS total_quantity,
        COALESCE(scs.store_revenue, 0) + COALESCE(wcs.web_revenue, 0) AS total_revenue,
        COALESCE(scs.store_customer_cnt, 0) + COALESCE(wcs.web_customer_cnt, 0) AS total_customer_cnt
    FROM store_category_sales scs
    FULL OUTER JOIN web_category_sales wcs
        ON scs.i_category_id = wcs.i_category_id
    LEFT JOIN stores s
        ON scs.ss_store_id = s.s_store_id
)
SELECT
    ccs.store_name,
    ccs.category_name,
    ccs.total_quantity,
    ccs.total_revenue,
    ccs.total_customer_cnt,
    cr.avg_rating,
    cr.review_count
FROM combined_category_sales ccs
LEFT JOIN category_ratings cr
    ON ccs.category_id = cr.i_category_id
ORDER BY ccs.total_revenue DESC
LIMIT 50
