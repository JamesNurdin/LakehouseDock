WITH sales_returns AS (
   SELECT
      cs.cs_sold_date_sk,
      d.d_year,
      d.d_month_seq,
      cs.cs_item_sk,
      i.i_category,
      i.i_brand,
      i.i_item_desc,
      i.i_product_name,
      sm.sm_type,
      w.w_warehouse_name,
      cs.cs_net_paid,
      cr.cr_return_amount
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
   WHERE i.i_item_desc LIKE '%steel%'
     AND regexp_like(i.i_item_desc, '(?i)steel')
)
SELECT
   d_year,
   i_category,
   i_brand,
   any_value(concat(i_brand, ' ', substring(i_product_name, 1, 10))) AS brand_product_prefix,
   any_value(regexp_extract(i_item_desc, '([A-Za-z]+)', 1)) AS first_word_desc,
   SUM(cs_net_paid) AS total_sales,
   SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
   SUM(cs_net_paid - COALESCE(cr_return_amount, 0)) AS net_sales
FROM sales_returns
GROUP BY ROLLUP (d_year, i_category, i_brand)
LIMIT 100
