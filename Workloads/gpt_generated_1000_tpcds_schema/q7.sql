WITH filtered_items AS (
    SELECT i_item_sk,
           i_category,
           i_item_desc,
           i_product_name,
           regexp_extract(i_item_desc, '([A-Z]{2}[0-9]{3})', 1) AS code,
           concat(i_brand, '-', i_product_name) AS brand_product
    FROM tpcds.item
    WHERE regexp_like(i_item_desc, '[0-9]{3}')
      AND i_product_name LIKE '%RED%'
)
SELECT d.d_year,
       d.d_month_seq AS month,
       f.i_category,
       sum(ss.ss_net_profit) AS total_profit,
       count(*) AS sales_cnt,
       max(f.code) AS example_code,
       max(f.brand_product) AS example_brand_product
FROM tpcds.store_sales ss
JOIN tpcds.date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN filtered_items f
  ON ss.ss_item_sk = f.i_item_sk
WHERE ss.ss_item_sk NOT IN (
    SELECT cr.cr_item_sk
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_return_amount > 0
)
GROUP BY d.d_year, d.d_month_seq, f.i_category
ORDER BY d.d_year DESC, d.d_month_seq ASC, total_profit DESC
