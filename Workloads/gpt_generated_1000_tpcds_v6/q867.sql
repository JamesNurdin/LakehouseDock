WITH
  returns_agg AS (
    SELECT
      i.i_brand AS brand,
      i.i_category AS category,
      CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
      DATE_TRUNC('month', d.d_date) AS month,
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_tier,
      REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS first_number,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt,
      CAST(NULL AS decimal(7,2)) AS total_sales_amount,
      CAST(NULL AS integer) AS sales_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '[A-Za-z]{3}\\d{3}')
      AND i.i_item_desc LIKE '%steel%'
    GROUP BY
      i.i_brand,
      i.i_category,
      CONCAT(i.i_brand, '-', i.i_category),
      DATE_TRUNC('month', d.d_date),
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END,
      REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1)
  ),
  sales_agg AS (
    SELECT
      i.i_brand AS brand,
      i.i_category AS category,
      CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
      DATE_TRUNC('month', d.d_date) AS month,
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_tier,
      REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS first_number,
      CAST(NULL AS decimal(7,2)) AS total_return_amount,
      CAST(NULL AS integer) AS return_cnt,
      SUM(ws.ws_ext_sales_price) AS total_sales_amount,
      COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '[A-Za-z]{3}\\d{3}')
      AND i.i_item_desc LIKE '%steel%'
    GROUP BY
      i.i_brand,
      i.i_category,
      CONCAT(i.i_brand, '-', i.i_category),
      DATE_TRUNC('month', d.d_date),
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END,
      REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1)
  )
SELECT
  brand,
  category,
  brand_category,
  month,
  price_tier,
  first_number,
  total_return_amount,
  total_sales_amount,
  return_cnt,
  sales_cnt
FROM (
  SELECT * FROM returns_agg
  UNION ALL
  SELECT * FROM sales_agg
) u
ORDER BY month DESC, brand ASC, total_sales_amount DESC
