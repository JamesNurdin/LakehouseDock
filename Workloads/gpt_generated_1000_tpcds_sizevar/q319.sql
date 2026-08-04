SELECT cs_order_number,
       cs_ext_sales_price,
       cs_net_profit
FROM tpcds.catalog_sales
WHERE cs_sold_date_sk = 2450820
  AND cs_wholesale_cost > 50.00
