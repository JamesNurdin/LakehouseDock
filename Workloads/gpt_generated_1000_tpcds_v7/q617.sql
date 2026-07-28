SELECT
    w.w_warehouse_name,
    t.t_meal_time,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MAX(ws.ws_ext_discount_amt) AS max_discount
FROM web_sales ws
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE w.w_street_type = 'Parkway'
  AND t.t_hour BETWEEN 9 AND 17
  AND hd.hd_dep_count = 4
GROUP BY w.w_warehouse_name, t.t_meal_time, hd.hd_buy_potential, ib.ib_lower_bound
ORDER BY total_net_paid DESC
LIMIT 100
