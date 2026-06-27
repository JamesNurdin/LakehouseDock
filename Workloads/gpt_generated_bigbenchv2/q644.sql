WITH
  item_ratings AS (
    SELECT
      i.i_item_id,
      AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
  ),
  store_sales_agg AS (
    SELECT
      ss.ss_store_id,
      SUM(ss.ss_quantity) AS total_quantity,
      SUM(ss.ss_quantity * i.i_price) AS total_revenue,
      COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
      COUNT(DISTINCT ss.ss_item_id) AS distinct_items
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
  ),
  store_item_rating AS (
    SELECT
      ss.ss_store_id,
      AVG(ir.avg_rating) AS avg_item_rating
    FROM store_sales ss
    JOIN item_ratings ir ON ss.ss_item_id = ir.i_item_id
    GROUP BY ss.ss_store_id
  )
SELECT
  s.s_store_name,
  agg.total_quantity,
  agg.total_revenue,
  rating.avg_item_rating,
  agg.distinct_customers,
  agg.distinct_items
FROM stores s
JOIN store_sales_agg agg ON s.s_store_id = agg.ss_store_id
LEFT JOIN store_item_rating rating ON s.s_store_id = rating.ss_store_id
ORDER BY agg.total_revenue DESC
