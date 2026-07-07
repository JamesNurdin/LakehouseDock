WITH sales_union AS (
    SELECT ss_item_id AS item_id, ss_quantity AS qty
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS qty
    FROM web_sales
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       SUM(su.qty) AS total_quantity,
       COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count
FROM sales_union su
JOIN items i ON su.item_id = i.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
GROUP BY i.i_item_id, i.i_name, i.i_category, i.i_price, ra.avg_sentiment, ra.review_count
ORDER BY total_quantity DESC
LIMIT 10
