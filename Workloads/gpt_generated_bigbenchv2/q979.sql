WITH store_category_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
online_category_sales AS (
    SELECT
        i.i_category AS category,
        SUM(ws.ws_quantity) AS total_online_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
category_sentiment AS (
    SELECT
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
category_price AS (
    SELECT
        i.i_category AS category,
        AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    scs.category,
    scs.total_store_qty,
    ocs.total_online_qty,
    cs.avg_sentiment,
    cp.avg_price
FROM store_category_sales scs
JOIN stores s ON scs.ss_store_id = s.s_store_id
LEFT JOIN online_category_sales ocs ON scs.category = ocs.category
LEFT JOIN category_sentiment cs ON scs.category = cs.category
LEFT JOIN category_price cp ON scs.category = cp.category
ORDER BY s.s_store_name, scs.category
