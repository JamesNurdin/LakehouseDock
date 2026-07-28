SELECT i.i_item_id,
       i.i_product_name,
       sum(ss.ss_ext_sales_price) AS total_sales,
       sum(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM tpcds.item i
JOIN tpcds.store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
WHERE i.i_formulation LIKE '%steel%'
  AND ss.ss_net_paid_inc_tax > 500
GROUP BY i.i_item_id, i.i_product_name
ORDER BY total_sales DESC
LIMIT 100
