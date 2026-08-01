SELECT DISTINCT cs_ship_customer_sk,
       cs_list_price,
       cs_ext_ship_cost
FROM catalog_sales
WHERE cs_list_price > 100.00
  AND cs_ext_ship_cost < 1000.00
ORDER BY cs_ship_customer_sk
LIMIT 100
