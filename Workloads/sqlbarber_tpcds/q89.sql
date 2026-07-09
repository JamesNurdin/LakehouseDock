SELECT ws.ws_sold_date_sk,
       ws.ws_item_sk,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_ext_sales_price * ws.ws_quantity AS total_sales,
       CASE
           WHEN cd.cd_gender = 'F' THEN ws.ws_net_profit
           WHEN cd.cd_gender = 'M' THEN ws.ws_net_profit * 0.9
           ELSE ws.ws_net_profit * 0.8
       END AS adjusted_profit,
       (ws.ws_ext_sales_price - ws.ws_ext_discount_amt) * ws.ws_quantity AS net_revenue,
       CASE WHEN ws.ws_ext_sales_price > 0.00 THEN 'High' ELSE 'Low' END AS price_category
FROM web_sales ws
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE ws.ws_sold_date_sk BETWEEN 2451488 AND 2452577
