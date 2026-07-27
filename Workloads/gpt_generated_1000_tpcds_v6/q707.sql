SELECT
    ca.ca_state,
    i.i_category,
    td.t_hour,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(*) AS order_cnt,
    MIN(ws.ws_ext_ship_cost) AS min_ship_cost,
    MAX(ws.ws_ext_wholesale_cost) AS max_wholesale_cost
FROM web_sales ws
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ws.ws_ext_wholesale_cost > 500
  AND ws.ws_ext_ship_cost < 2000
  AND ws.ws_net_profit > -500
  AND td.t_hour BETWEEN 8 AND 16
  AND i.i_manufact_id IN (26, 117, 214)
  AND cust.c_birth_year = 1975
  AND ca.ca_state = 'CA'
GROUP BY ROLLUP (ca.ca_state, i.i_category, td.t_hour)
ORDER BY ca.ca_state, i.i_category, td.t_hour, total_sales DESC
LIMIT 100
