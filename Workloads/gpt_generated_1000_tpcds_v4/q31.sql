SELECT DISTINCT
    ws_ship_customer_sk,
    ws_item_sk,
    ws_ext_sales_price
FROM tpcds.web_sales
WHERE ws_ship_customer_sk IN (10398174, 1633483)
  AND ws_sold_date_sk = 2451879
LIMIT 100
