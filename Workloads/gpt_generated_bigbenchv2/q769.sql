WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_store_id AS store_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           NULL AS store_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    GROUP BY cs.item_id
),
item_ratings AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
item_details AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category_id,
           i.i_category_name,
           i.i_price,
           i.i_comp_price
    FROM items i
)
SELECT d.i_category_name,
       COUNT(d.i_item_id) AS num_items,
       SUM(s.total_quantity) AS total_quantity_sold,
       AVG(r.avg_rating) AS avg_item_rating,
       SUM(s.total_quantity * d.i_price) AS total_revenue
FROM item_details d
JOIN item_sales s
  ON d.i_item_id = s.item_id
LEFT JOIN item_ratings r
  ON d.i_item_id = r.item_id
GROUP BY d.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 10
