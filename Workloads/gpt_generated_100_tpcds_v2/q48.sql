SELECT 'warehouse' AS group_type,
       w.w_warehouse_name AS group_key,
       SUM(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2020
GROUP BY w.w_warehouse_name
UNION ALL
SELECT 'demographic' AS group_type,
       CAST(hd.hd_income_band_sk AS VARCHAR) AS group_key,
       SUM(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2020
GROUP BY hd.hd_income_band_sk
