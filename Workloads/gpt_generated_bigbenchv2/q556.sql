WITH
  total_sales AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity
    FROM (
      SELECT ss_item_id AS item_id,
             ss_quantity AS quantity
      FROM store_sales
      UNION ALL
      SELECT ws_item_id AS item_id,
             ws_quantity AS quantity
      FROM web_sales
    ) t
    GROUP BY item_id
  ),
  review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
  ),
  distinct_customers AS (
    SELECT item_id,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM (
      SELECT ss_item_id AS item_id,
             ss_customer_id AS customer_id
      FROM store_sales
      UNION ALL
      SELECT ws_item_id AS item_id,
             ws_customer_id AS customer_id
      FROM web_sales
    ) t
    GROUP BY item_id
  ),
  top_store_per_item AS (
    SELECT item_id,
           store_id,
           store_quantity
    FROM (
      SELECT item_id,
             store_id,
             store_quantity,
             ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY store_quantity DESC) AS rn
      FROM (
        SELECT ss_item_id AS item_id,
               ss_store_id AS store_id,
               SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id, ss_store_id
      ) agg
    ) ranked
    WHERE rn = 1
  )
SELECT
  i.i_item_id,
  i.i_name,
  i.i_category_name,
  i.i_price,
  COALESCE(ts.total_quantity, 0) AS total_quantity_sold,
  ra.avg_rating,
  ra.review_count,
  dc.distinct_customers,
  s.s_store_name AS top_store_name,
  tsp.store_quantity AS top_store_quantity
FROM items i
LEFT JOIN total_sales ts ON i.i_item_id = ts.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
LEFT JOIN distinct_customers dc ON i.i_item_id = dc.item_id
LEFT JOIN top_store_per_item tsp ON i.i_item_id = tsp.item_id
LEFT JOIN stores s ON tsp.store_id = s.s_store_id
ORDER BY total_quantity_sold DESC
LIMIT 10
