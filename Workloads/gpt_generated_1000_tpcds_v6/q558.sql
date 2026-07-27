WITH filtered_items AS (
   SELECT
       i_item_sk,
       i_manufact,
       i_product_name,
       i_container,
       regexp_extract(i_item_desc, '(\\d+)', 1) AS first_number,
       concat(i_brand, ' - ', i_product_name) AS brand_product,
       substring(i_item_id, 1, 3) AS item_prefix
   FROM item
   WHERE regexp_like(i_manufact, '^e')
     AND i_container LIKE '%Unknown%'
)

SELECT
    f.i_manufact,
    f.item_prefix,
    f.brand_product,
    f.first_number,
    COUNT(*) AS sold_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    SUM(ss.ss_ext_discount_amt) AS total_discount
FROM filtered_items f
JOIN store_sales ss
  ON ss.ss_item_sk = f.i_item_sk
WHERE ss.ss_ext_sales_price > 1000
GROUP BY f.i_manufact, f.item_prefix, f.brand_product, f.first_number
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
