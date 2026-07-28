SELECT
    d_sold.d_year,
    cd_bill.cd_gender,
    w.w_state,
    s.s_market_id,
    r.r_reason_desc,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(cs.cs_quantity) AS avg_catalog_quantity,
    MAX(ws.ws_net_profit) AS max_web_profit,
    MIN(inv.inv_quantity_on_hand) AS min_inventory_on_hand
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship
  ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN catalog_sales cs
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
 AND cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
 AND inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_ret
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
  ON wr.wr_returned_time_sk = t_ret.t_time_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE d_sold.d_year = 1915
  AND cd_bill.cd_gender = 'M'
  AND r.r_reason_desc = 'Gift exchange'
  AND w.w_state = 'CA'
GROUP BY
    d_sold.d_year,
    cd_bill.cd_gender,
    w.w_state,
    s.s_market_id,
    r.r_reason_desc
ORDER BY total_catalog_sales DESC
LIMIT 100
