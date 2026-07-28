SELECT
    ss_sold_date_sk,
    ss_store_sk,
    ss_ext_sales_price,
    ss_ext_tax,
    ss_net_profit
FROM tpcds.store_sales
WHERE ss_ext_sales_price > 2000.00
  AND ss_ext_tax < 50.00
ORDER BY ss_ext_sales_price DESC
LIMIT 100
