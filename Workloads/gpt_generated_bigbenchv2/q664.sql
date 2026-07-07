WITH sales_per_item AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity FROM web_sales
    ) s
    GROUP BY item_id
),
sales_per_category AS (
    SELECT i.i_category_id, i.i_category, SUM(s.total_quantity) AS category_quantity
    FROM sales_per_item s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
avg_sentiment_per_category AS (
    SELECT i.i_category_id, i.i_category, AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT spc.i_category_id,
       spc.i_category,
       spc.category_quantity,
       aspc.avg_sentiment
FROM sales_per_category spc
JOIN avg_sentiment_per_category aspc ON spc.i_category_id = aspc.i_category_id
ORDER BY spc.category_quantity DESC
LIMIT 5
