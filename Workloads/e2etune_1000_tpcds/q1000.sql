SELECT
    wsite.web_site_id,
    wsite.web_name,
    td.t_hour,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_bill_customers,
    COUNT(DISTINCT ws.ws_ship_customer_sk) AS distinct_ship_customers,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_to_sales_ratio
FROM web_sales ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE ws.ws_ext_discount_amt > 0
  AND cd_bill.cd_credit_rating IN ('A', 'B')
  AND cd_ship.cd_credit_rating IN ('A', 'B')
  AND td.t_meal_time = 'Dinner'
GROUP BY wsite.web_site_id, wsite.web_name, td.t_hour
ORDER BY total_net_profit DESC
LIMIT 100
