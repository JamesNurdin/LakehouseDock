WITH
store_sales_agg AS (
    SELECT ss.ss_store_id AS store_id,
           i.i_category,
           SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
web_sales_agg AS (
    SELECT CAST(NULL AS BIGINT) AS store_id,
           i.i_category,
           SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
sales_combined AS (
    SELECT COALESCE(s.s_store_name, 'Online') AS store_name,
           agg.i_category,
           agg.quantity
    FROM (
        SELECT store_id, i_category, quantity FROM store_sales_agg
        UNION ALL
        SELECT store_id, i_category, quantity FROM web_sales_agg
    ) agg
    LEFT JOIN stores s ON agg.store_id = s.s_store_id
),
category_sentiment AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT sc.store_name,
       sc.i_category,
       SUM(sc.quantity) AS total_quantity,
       cs.avg_sentiment
FROM sales_combined sc
JOIN category_sentiment cs ON sc.i_category = cs.i_category
GROUP BY sc.store_name, sc.i_category, cs.avg_sentiment
ORDER BY sc.store_name, sc.i_category
