WITH sales_per_category AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(COALESCE(st.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity_sold,
           AVG(i.i_price) AS avg_price,
           COUNT(DISTINCT i.i_item_id) AS num_items
    FROM items i
    LEFT JOIN (
        SELECT ss_item_id, SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ) st ON st.ss_item_id = i.i_item_id
    LEFT JOIN (
        SELECT ws_item_id, SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ) ws ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_per_category AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS num_reviews
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT s.i_category_id,
       s.i_category,
       s.total_quantity_sold,
       s.avg_price,
       s.num_items,
       r.avg_sentiment,
       r.num_reviews
FROM sales_per_category s
LEFT JOIN reviews_per_category r
    ON r.i_category_id = s.i_category_id
   AND r.i_category = s.i_category
ORDER BY s.total_quantity_sold DESC
LIMIT 10
