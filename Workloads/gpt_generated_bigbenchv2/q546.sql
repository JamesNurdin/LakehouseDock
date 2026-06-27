WITH
  -- Average rating per item from product reviews
  item_ratings AS (
    SELECT
      pr_item_id AS i_item_id,
      AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
  ),

  -- Normalise store sales to a common sales shape
  store_sales_agg AS (
    SELECT
      ss.ss_customer_id AS customer_id,
      ss.ss_item_id     AS item_id,
      ss.ss_quantity    AS quantity,
      CAST('store' AS VARCHAR) AS channel
    FROM store_sales ss
  ),

  -- Normalise web sales to the same shape
  web_sales_agg AS (
    SELECT
      ws.ws_customer_id AS customer_id,
      ws.ws_item_id     AS item_id,
      ws.ws_quantity    AS quantity,
      CAST('web' AS VARCHAR)   AS channel
    FROM web_sales ws
  ),

  -- Combine the two sales sources
  combined_sales AS (
    SELECT
      customer_id,
      item_id,
      quantity,
      channel
    FROM store_sales_agg
    UNION ALL
    SELECT
      customer_id,
      item_id,
      quantity,
      channel
    FROM web_sales_agg
  )
SELECT
  i.i_category_id,
  i.i_category_name,
  COUNT(DISTINCT c.c_customer_id)                     AS distinct_customers,
  SUM(cs.quantity)                                   AS total_quantity,
  SUM(cs.quantity * i.i_price)                       AS total_revenue,
  AVG(ir.avg_rating)                                 AS avg_item_rating,
  COUNT(DISTINCT cs.channel)                         AS sales_channels
FROM combined_sales cs
JOIN items i
  ON cs.item_id = i.i_item_id
JOIN customers c
  ON cs.customer_id = c.c_customer_id
LEFT JOIN item_ratings ir
  ON i.i_item_id = ir.i_item_id
GROUP BY
  i.i_category_id,
  i.i_category_name
ORDER BY total_revenue DESC
