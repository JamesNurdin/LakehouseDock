WITH store_sales_agg AS (
    SELECT s.s_store_name,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT ssa.s_store_name,
       ssa.i_category,
       ssa.store_quantity,
       COALESCE(wsa.web_quantity, 0) AS web_quantity,
       COALESCE(ra.avg_sentiment, 0) AS avg_sentiment
FROM store_sales_agg ssa
LEFT JOIN web_sales_agg wsa ON ssa.i_category = wsa.i_category
LEFT JOIN review_agg ra ON ssa.i_category = ra.i_category
ORDER BY ssa.s_store_name, ssa.i_category
