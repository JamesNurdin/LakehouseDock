WITH
price AS (
    SELECT i.i_category,
           AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category
),
instore AS (
    SELECT i.i_category,
           s.s_store_name,
           SUM(ss.ss_quantity) AS total_instore_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category, s.s_store_name
),
online AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_online_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    p.i_category,
    COALESCE(i.s_store_name, 'Online Only') AS store_name,
    COALESCE(i.total_instore_qty, 0) AS total_instore_qty,
    COALESCE(o.total_online_qty, 0) AS total_online_qty,
    r.avg_sentiment,
    p.avg_price
FROM price p
LEFT JOIN instore i ON p.i_category = i.i_category
LEFT JOIN online o ON p.i_category = o.i_category
LEFT JOIN reviews r ON p.i_category = r.i_category
ORDER BY p.i_category, store_name
