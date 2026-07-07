WITH item_reviews AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category
),
store_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ssa.total_store_quantity, 0) + COALESCE(wsa.total_web_quantity, 0) AS total_quantity,
    COALESCE(ir.avg_sentiment, 0) AS avg_sentiment,
    i.i_price
FROM items i
LEFT JOIN store_sales_agg ssa
    ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa
    ON i.i_item_id = wsa.i_item_id
LEFT JOIN item_reviews ir
    ON i.i_item_id = ir.i_item_id
WHERE COALESCE(ssa.total_store_quantity, 0) + COALESCE(wsa.total_web_quantity, 0) > 0
ORDER BY total_quantity DESC, avg_sentiment DESC
LIMIT 10
