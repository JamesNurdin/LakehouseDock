WITH distinct_customers AS (
    SELECT DISTINCT c_customer_sk, c_first_name, c_last_name
    FROM customer
),
inv_agg AS (
    SELECT inv_warehouse_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    ws.ws_order_number,
    d_sold.d_date AS sold_date,
    CONCAT(cb.c_first_name, ' ', cb.c_last_name) AS bill_customer_name,
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS ship_customer_name,
    w.w_warehouse_name,
    sm.sm_type AS ship_mode,
    st.s_store_name,
    cc.cc_city,
    cp.cp_department,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_returns_loss,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_returns_loss,
    COALESCE(ia.total_qty, 0) AS inventory_on_hand
FROM web_sales ws
TABLESAMPLE BERNOULLI (10)
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN distinct_customers cb
  ON ws.ws_bill_customer_sk = cb.c_customer_sk
JOIN distinct_customers cs
  ON ws.ws_ship_customer_sk = cs.c_customer_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d_sold.d_date_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN store_returns sr
  ON sr.sr_customer_sk = cb.c_customer_sk
LEFT JOIN store st
  ON sr.sr_store_sk = st.s_store_sk
LEFT JOIN date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN inv_agg ia
  ON ia.inv_warehouse_sk = w.w_warehouse_sk
 AND ia.inv_date_sk = d_sold.d_date_sk
GROUP BY
    ws.ws_order_number,
    d_sold.d_date,
    cb.c_first_name,
    cb.c_last_name,
    cs.c_first_name,
    cs.c_last_name,
    w.w_warehouse_name,
    sm.sm_type,
    st.s_store_name,
    cc.cc_city,
    cp.cp_department,
    ia.total_qty
ORDER BY total_sales DESC
LIMIT 100
