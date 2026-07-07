WITH category_sentiment AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
store_sales_agg AS (
    SELECT i.i_category,
           s.s_store_name,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category, s.s_store_name
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    ssag.i_category AS category,
    ssag.s_store_name AS store_name,
    ssag.total_store_quantity,
    COALESCE(wsag.total_web_quantity, 0) AS total_web_quantity,
    cs.avg_sentiment
FROM store_sales_agg ssag
LEFT JOIN web_sales_agg wsag
    ON ssag.i_category = wsag.i_category
LEFT JOIN category_sentiment cs
    ON ssag.i_category = cs.i_category
ORDER BY ssag.i_category, ssag.s_store_name
