WITH sales_agg AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    SUM(ss.ss_quantity)               AS total_qty,
    SUM(ss.ss_net_paid)               AS total_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 1999
    AND regexp_like(i.i_product_name, '^A.*')
  GROUP BY i.i_item_sk, i.i_product_name, i.i_category
),

high_sales AS (
  SELECT * FROM sales_agg WHERE total_sales > 10000
),

low_sales AS (
  SELECT * FROM sales_agg WHERE total_sales <= 10000
)

SELECT DISTINCT
  h.i_item_sk,
  h.i_product_name,
  h.i_category,
  h.total_qty,
  h.total_sales,
  substr(h.i_product_name, 1, 5)                AS prod_prefix,
  concat('Category: ', h.i_category)            AS category_label,
  (SELECT max(d_year) FROM date_dim)           AS max_year
FROM high_sales h
WHERE NOT EXISTS (
  SELECT 1
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_item_sk = h.i_item_sk
    AND regexp_like(r.r_reason_desc, '.*defect.*')
)

UNION ALL

SELECT DISTINCT
  l.i_item_sk,
  l.i_product_name,
  l.i_category,
  l.total_qty,
  l.total_sales,
  substr(l.i_product_name, 1, 5)                AS prod_prefix,
  concat('Category: ', l.i_category)            AS category_label,
  (SELECT max(d_year) FROM date_dim)           AS max_year
FROM low_sales l
WHERE l.total_qty > 0
  AND NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = l.i_item_sk
  )

ORDER BY total_sales DESC
LIMIT 100
