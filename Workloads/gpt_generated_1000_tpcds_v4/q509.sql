WITH item_sales AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY ss.ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    regexp_extract(i.i_item_desc, '(\\d+)', 1) AS first_number_in_desc,
    CONCAT(i.i_brand, ' ', i.i_category) AS brand_category,
    CASE WHEN i.i_product_name LIKE '%Premium%' THEN 'Premium' ELSE 'Standard' END AS product_tier,
    isales.total_net_paid,
    isales.total_sales,
    isales.sales_cnt,
    (isales.total_net_paid / isales.sales_cnt) AS avg_net_per_sale
FROM item i
JOIN item_sales isales ON i.i_item_sk = isales.ss_item_sk
WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
  AND EXISTS (
      SELECT 1
      FROM store_sales ss2
      JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
      WHERE ss2.ss_item_sk = i.i_item_sk
        AND d2.d_year = 2023
        AND ss2.ss_net_paid > 1000
  )
ORDER BY isales.total_sales DESC
LIMIT 100
