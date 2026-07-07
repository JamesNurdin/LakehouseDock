WITH sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity FROM web_sales
),
item_sales_agg AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY item_id
),
item_sentiment_agg AS (
    SELECT pr_item_id AS item_id, AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(COALESCE(s.total_quantity, 0)) AS category_total_quantity,
    AVG(r.avg_sentiment) AS category_avg_sentiment,
    AVG(i.i_price) AS category_avg_price
FROM items i
LEFT JOIN item_sales_agg s ON s.item_id = i.i_item_id
LEFT JOIN item_sentiment_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY category_total_quantity DESC
