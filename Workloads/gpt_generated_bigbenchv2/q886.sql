WITH sales_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS total_quantity,
           COUNT(*) AS sales_transactions
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_item_price,
       AVG(COALESCE(r.avg_sentiment, 0)) AS avg_sentiment,
       SUM(COALESCE(r.review_count, 0)) AS total_reviews,
       SUM(COALESCE(s.sales_transactions, 0)) AS total_sales_transactions
FROM items i
LEFT JOIN sales_agg s ON s.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
WHERE i.i_price > 10.00
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 20
