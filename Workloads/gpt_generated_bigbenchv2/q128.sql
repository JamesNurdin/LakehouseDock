WITH sales AS (
    SELECT ss_item_id AS item_id, SUM(ss_quantity) AS quantity
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT ws_item_id AS item_id, SUM(ws_quantity) AS quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales_agg AS (
    SELECT s.item_id, SUM(s.quantity) AS total_quantity
    FROM sales s
    GROUP BY s.item_id
),
item_reviews_agg AS (
    SELECT pr.pr_item_id AS item_id, AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category AS category,
       SUM(isag.total_quantity) AS total_quantity_sold,
       AVG(irag.avg_sentiment) AS avg_review_sentiment
FROM item_sales_agg isag
JOIN items i ON isag.item_id = i.i_item_id
JOIN item_reviews_agg irag ON i.i_item_id = irag.item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
