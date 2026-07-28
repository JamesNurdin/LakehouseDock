SELECT
    i.i_category,
    i.i_color,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_net_profit) AS avg_profit
FROM tpcds.web_sales ws
JOIN tpcds.item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
WHERE ws.ws_ship_addr_sk = 3712053
  AND i.i_color = 'yellow'
  AND cr.cr_store_credit >= 30.00
GROUP BY i.i_category, i.i_color
HAVING SUM(ws.ws_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 20
