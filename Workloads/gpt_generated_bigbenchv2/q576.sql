-- Total store and web sales metrics by store and item category, with average product rating
WITH store_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
rating_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    s.s_store_name,
    sa.i_category_name,
    sa.store_quantity,
    sa.store_revenue,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    ra.avg_rating,
    sa.store_customer_count
FROM store_agg sa
JOIN stores s
    ON sa.store_id = s.s_store_id
LEFT JOIN web_agg wa
    ON sa.i_category_id = wa.i_category_id
LEFT JOIN rating_agg ra
    ON sa.i_category_id = ra.i_category_id
ORDER BY
    s.s_store_name,
    sa.i_category_name
