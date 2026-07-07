WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS qty
    FROM web_sales
    GROUP BY ws_item_id
),
combined_sales AS (
    SELECT item_id,
           qty
    FROM store_sales_agg
    UNION ALL
    SELECT item_id,
           qty
    FROM web_sales_agg
),
item_sales AS (
    SELECT item_id,
           SUM(qty) AS total_qty
    FROM combined_sales
    GROUP BY item_id
),
item_reviews AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       SUM(s.total_qty) AS category_total_qty,
       AVG(r.avg_sentiment) AS category_avg_sentiment,
       COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM item_sales s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN item_reviews r ON r.item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY category_total_qty DESC
LIMIT 10
