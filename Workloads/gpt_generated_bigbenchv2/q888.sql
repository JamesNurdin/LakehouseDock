WITH sales_union AS (
  -- Combine store and web sales into a single stream
  SELECT
    ss.ss_quantity   AS quantity,
    ss.ss_item_id    AS item_id,
    'store'          AS channel
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_quantity   AS quantity,
    ws.ws_item_id    AS item_id,
    'web'            AS channel
  FROM web_sales ws
),

sales_agg AS (
  -- Aggregate sales by item category across both channels
  SELECT
    i.i_category_name                                    AS i_category_name,
    SUM(su.quantity)                                     AS total_quantity,
    SUM(su.quantity * i.i_price)                         AS total_revenue,
    COUNT(DISTINCT CASE WHEN su.channel = 'store' THEN su.item_id END) AS distinct_store_items,
    COUNT(DISTINCT CASE WHEN su.channel = 'web'   THEN su.item_id END) AS distinct_web_items
  FROM sales_union su
  JOIN items i ON su.item_id = i.i_item_id
  GROUP BY i.i_category_name
)
SELECT
  s.i_category_name,
  s.total_quantity,
  s.total_revenue,
  s.distinct_store_items,
  s.distinct_web_items,
  (
    SELECT AVG(pr.pr_rating)
    FROM product_reviews pr
    JOIN items i2 ON pr.pr_item_id = i2.i_item_id
    WHERE i2.i_category_name = s.i_category_name
  ) AS avg_rating,
  (
    SELECT COUNT(pr.pr_review_id)
    FROM product_reviews pr
    JOIN items i2 ON pr.pr_item_id = i2.i_item_id
    WHERE i2.i_category_name = s.i_category_name
  ) AS review_count
FROM sales_agg s
ORDER BY s.total_revenue DESC
LIMIT 20
