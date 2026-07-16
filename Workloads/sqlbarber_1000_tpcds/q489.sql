SELECT
    w.w_warehouse_name,
    SUM(cs.cs_net_paid) AS total_sales,
    COUNT(cr.cr_return_quantity) AS total_returns,
    (SELECT ws2.ws_sold_date_sk
     FROM web_sales ws2
     WHERE ws2.ws_sold_date_sk = CAST(2451542 AS integer)
     LIMIT 1) AS sample_sold_date
FROM catalog_sales cs
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_sold_date_sk = CAST(2451142 AS integer)
GROUP BY w.w_warehouse_name, w.w_warehouse_sk
HAVING SUM(cs.cs_net_paid) > 2656.20
