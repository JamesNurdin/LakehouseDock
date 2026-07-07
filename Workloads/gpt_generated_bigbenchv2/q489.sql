WITH sales_union AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
aggregated_sales AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM sales_union
    GROUP BY item_id
),
item_sentiment AS (
    SELECT pr_item_id AS item_id, AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       a.total_quantity,
       COALESCE(s.avg_sentiment, 0) AS avg_sentiment
FROM aggregated_sales a
JOIN items i
  ON a.item_id = i.i_item_id
LEFT JOIN item_sentiment s
  ON i.i_item_id = s.item_id
ORDER BY a.total_quantity DESC
LIMIT 10
