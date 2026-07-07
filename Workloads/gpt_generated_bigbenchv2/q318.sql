WITH category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ws.ws_quantity) AS web_quantity,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM items i
    LEFT JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    LEFT JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    i_category_id,
    i_category,
    store_quantity,
    web_quantity,
    avg_sentiment
FROM category_sales
ORDER BY store_quantity DESC, web_quantity DESC
