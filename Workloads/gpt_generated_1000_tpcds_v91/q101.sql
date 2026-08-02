SELECT ws_sold_date_sk,
       sum(ws_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
       sum(ws_ext_wholesale_cost) AS total_wholesale_cost,
       count(*) AS order_count
FROM tpcds.web_sales
WHERE ws_net_paid_inc_ship_tax > 5000.00
  AND ws_ext_wholesale_cost < 1000.00
GROUP BY ws_sold_date_sk
ORDER BY total_net_paid_inc_ship_tax DESC
LIMIT 100
