WITH store_category_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
category_total_quantity AS (
    SELECT
        combined.i_category_id,
        combined.i_category_name,
        SUM(combined.qty) AS total_quantity_all
    FROM (
        SELECT i.i_category_id, i.i_category_name, SUM(ss.ss_quantity) AS qty
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name

        UNION ALL

        SELECT i.i_category_id, i.i_category_name, SUM(ws.ws_quantity) AS qty
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ) combined
    GROUP BY combined.i_category_id, combined.i_category_name
),
category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_id,
    s.s_store_name,
    scs.i_category_id,
    scs.i_category_name,
    scs.store_quantity,
    ctq.total_quantity_all,
    CAST(scs.store_quantity AS double) / NULLIF(ctq.total_quantity_all, 0) AS store_share,
    scs.store_revenue,
    cr.avg_rating,
    scs.distinct_customers
FROM store_category_sales scs
JOIN stores s ON scs.ss_store_id = s.s_store_id
LEFT JOIN category_total_quantity ctq
    ON scs.i_category_id = ctq.i_category_id
    AND scs.i_category_name = ctq.i_category_name
LEFT JOIN category_ratings cr
    ON scs.i_category_id = cr.i_category_id
    AND scs.i_category_name = cr.i_category_name
ORDER BY scs.store_revenue DESC
LIMIT 20
