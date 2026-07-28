WITH sales AS (
  SELECT
    i.i_item_id,
    'sales' AS activity,
    SUM(cs.cs_ext_sales_price) AS total_amount,
    CASE
      WHEN i.i_current_price < 20 THEN 'Low'
      WHEN i.i_current_price BETWEEN 20 AND 50 THEN 'Medium'
      ELSE 'High'
    END AS price_category,
    (SELECT AVG(i2.i_current_price)
       FROM item i2
      WHERE i2.i_brand = i.i_brand) AS avg_brand_price
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY i.i_item_id, i.i_current_price, i.i_brand
),
returns AS (
  SELECT
    i.i_item_id,
    'return' AS activity,
    -SUM(cr.cr_return_amount) AS total_amount,
    CASE
      WHEN i.i_current_price < 20 THEN 'Low'
      WHEN i.i_current_price BETWEEN 20 AND 50 THEN 'Medium'
      ELSE 'High'
    END AS price_category,
    (SELECT AVG(i2.i_current_price)
       FROM item i2
      WHERE i2.i_brand = i.i_brand) AS avg_brand_price
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
    AND EXISTS (
        SELECT 1 FROM store_returns sr
         WHERE sr.sr_item_sk = i.i_item_sk
    )
  GROUP BY i.i_item_id, i.i_current_price, i.i_brand
),
combined AS (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
)
SELECT
  i_item_id,
  activity,
  total_amount,
  price_category,
  avg_brand_price,
  ROW_NUMBER() OVER (PARTITION BY activity ORDER BY total_amount DESC) AS activity_rank
FROM combined
WHERE total_amount <> 0
ORDER BY total_amount DESC
LIMIT 100
