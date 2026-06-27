WITH
  store_sales_agg AS (
    SELECT
      ss_item_id,
      SUM(ss_quantity) AS store_quantity,
      SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
  ),
  web_sales_agg AS (
    SELECT
      ws_item_id,
      SUM(ws_quantity) AS web_quantity,
      SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
  ),
  reviews_agg AS (
    SELECT
      pr_item_id,
      AVG(pr_rating) AS avg_rating,
      COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
  ),
  distinct_customer_counts AS (
    SELECT
      item_id,
      COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM (
      SELECT ss_item_id AS item_id, ss_customer_id AS customer_id FROM store_sales
      UNION ALL
      SELECT ws_item_id AS item_id, ws_customer_id AS customer_id FROM web_sales
    ) AS combined
    GROUP BY item_id
  )
SELECT
  i.i_category_id,
  i.i_category_name,
  SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity,
  SUM(COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0)) AS total_revenue,
  AVG(r.avg_rating) AS avg_rating,
  SUM(COALESCE(dc.distinct_customer_count, 0)) AS total_customers,
  SUM(COALESCE(r.review_count, 0)) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.pr_item_id
LEFT JOIN distinct_customer_counts dc ON i.i_item_id = dc.item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
