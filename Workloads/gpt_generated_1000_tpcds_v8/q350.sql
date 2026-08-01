SELECT cp.cp_description,
       cp.cp_catalog_page_number,
       cs.cs_order_number,
       cs.cs_ext_sales_price,
       cs.cs_net_profit
FROM tpcds.catalog_sales cs
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_catalog_page_number = 9
  AND cs.cs_ext_sales_price > 1500
LIMIT 100
