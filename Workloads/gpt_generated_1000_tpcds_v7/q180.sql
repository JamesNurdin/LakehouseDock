SELECT
   COALESCE(cp.cp_catalog_page_id, 'UNKNOWN') AS catalog_page_id,
   cp.cp_description,
   cd_bill.cd_gender AS bill_gender,
   cd_ship.cd_gender AS ship_gender,
   cd_current.cd_education_status,
   d_sold.d_year AS sold_year,
   SUM(ws.ws_net_profit) AS total_net_profit,
   COUNT(*) AS order_count
FROM web_sales ws
JOIN date_dim d_sold
   ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
   ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
   ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
   ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill
   ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
   ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_demographics cd_current
   ON c_bill.c_current_cdemo_sk = cd_current.cd_demo_sk
LEFT JOIN date_dim d_cp_start
   ON d_cp_start.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN catalog_page cp
   ON cp.cp_start_date_sk = d_cp_start.d_date_sk
LEFT JOIN date_dim d_cp_end
   ON d_cp_end.d_date_sk = cp.cp_end_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
   COALESCE(cp.cp_catalog_page_id, 'UNKNOWN'),
   cp.cp_description,
   cd_bill.cd_gender,
   cd_ship.cd_gender,
   cd_current.cd_education_status,
   d_sold.d_year
ORDER BY total_net_profit DESC
LIMIT 100
