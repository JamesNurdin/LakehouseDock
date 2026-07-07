WITH sales_qty AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS quantity
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_total_qty AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity
    FROM sales_qty
    GROUP BY item_id
)
SELECT i.i_category,
       COUNT(DISTINCT pr.pr_review_id) AS review_count,
       SUM(pr.pr_sentiment * COALESCE(itq.total_quantity, 0)) / NULLIF(SUM(COALESCE(itq.total_quantity, 0)), 0) AS weighted_avg_sentiment,
       SUM(COALESCE(itq.total_quantity, 0)) AS total_quantity_sold
FROM product_reviews pr
JOIN items i ON pr.pr_item_id = i.i_item_id
LEFT JOIN item_total_qty itq ON i.i_item_id = itq.item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
