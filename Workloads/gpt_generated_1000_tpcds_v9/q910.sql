SELECT
    d.d_date AS sale_date,
    t.t_hour,
    sm.sm_type,
    w.w_warehouse_name,
    cc.cc_name,
    ws.ws_net_profit,
    CASE WHEN ws.ws_net_profit > 1000 THEN 'High'
         WHEN ws.ws_net_profit > 0 THEN 'Medium'
         ELSE 'Low' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    (SELECT sum(ws_sub.ws_ext_sales_price)
       FROM web_sales ws_sub
      WHERE ws_sub.ws_bill_customer_sk = ws.ws_bill_customer_sk
        AND ws_sub.ws_sold_date_sk = ws.ws_sold_date_sk) AS cust_daily_total_sales
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
  ON d.d_date_sk = cc.cc_open_date_sk
WHERE d.d_year = 1998
  AND t.t_hour BETWEEN 9 AND 17
  AND sm.sm_type = 'AIR'
  AND w.w_warehouse_sq_ft >= 800000
  AND cc.cc_state = 'OH'
  AND ws.ws_quantity > 0
LIMIT 100
