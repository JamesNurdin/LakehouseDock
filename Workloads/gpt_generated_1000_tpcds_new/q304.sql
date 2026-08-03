WITH
  store_ret AS (
    SELECT
      sr.sr_customer_sk AS customer_sk,
      sr.sr_item_sk AS item_sk,
      d.d_year AS year,
      COUNT(*) AS store_ret_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)organic')
      AND i.i_product_name LIKE '%Eco%'
      AND substring(i.i_item_id, 1, 3) = '001'
    GROUP BY sr.sr_customer_sk, sr.sr_item_sk, d.d_year
  ),
  catalog_ret AS (
    SELECT
      cr.cr_refunded_customer_sk AS customer_sk,
      cr.cr_item_sk AS item_sk,
      d.d_year AS year,
      COUNT(*) AS catalog_ret_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)organic')
      AND i.i_product_name LIKE '%Eco%'
      AND substring(i.i_item_id, 1, 3) = '001'
    GROUP BY cr.cr_refunded_customer_sk, cr.cr_item_sk, d.d_year
  ),
  intersect_keys AS (
    SELECT customer_sk, item_sk, year FROM store_ret
    INTERSECT
    SELECT customer_sk, item_sk, year FROM catalog_ret
  )
SELECT
  c.c_customer_id,
  i.i_item_id,
  ik.year,
  sr.store_ret_cnt,
  cr.catalog_ret_cnt,
  (sr.store_ret_cnt + cr.catalog_ret_cnt) AS total_ret_cnt,
  concat(i.i_brand, '-', i.i_color) AS brand_color,
  regexp_extract(i.i_item_desc, '(\\d{3})') AS extracted_code
FROM intersect_keys ik
JOIN store_ret sr ON ik.customer_sk = sr.customer_sk AND ik.item_sk = sr.item_sk AND ik.year = sr.year
JOIN catalog_ret cr ON ik.customer_sk = cr.customer_sk AND ik.item_sk = cr.item_sk AND ik.year = cr.year
JOIN customer c ON ik.customer_sk = c.c_customer_sk
JOIN item i ON ik.item_sk = i.i_item_sk
WHERE EXISTS (
  SELECT 1
  FROM catalog_sales cs
  JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
  WHERE cs.cs_bill_customer_sk = ik.customer_sk
    AND cs.cs_item_sk = ik.item_sk
    AND d2.d_year = ik.year
    AND cs.cs_sales_price > 0
)
ORDER BY total_ret_cnt DESC, c.c_customer_id
LIMIT 100
