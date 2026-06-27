WITH review_agg AS (
    SELECT pr_item_id,
           COUNT(*) AS review_count,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS total_quantity,
           COUNT(*) AS sales_count
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       i.i_price,
       i.i_comp_price,
       r.review_count,
       r.avg_rating,
       s.total_quantity,
       s.sales_count,
       s.total_quantity * i.i_price AS total_revenue
FROM items i
JOIN review_agg r ON r.pr_item_id = i.i_item_id
JOIN sales_agg s ON s.ws_item_id = i.i_item_id
WHERE r.avg_rating >= 4
  AND s.total_quantity > 100
ORDER BY total_revenue DESC
LIMIT 20
