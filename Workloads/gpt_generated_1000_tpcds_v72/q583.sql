SELECT
    ca_bill.ca_state AS bill_state,
    w.w_state AS warehouse_state,
    d_sold.d_year AS sale_year,
    s1.s_store_name AS store_name,
    COUNT(*) AS orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid_inc_ship) AS avg_paid_inc_ship
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN store s1
  ON s1.s_closed_date_sk = d_sold.d_date_sk
JOIN store s2
  ON s2.s_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_store1
  ON s1.s_closed_date_sk = d_store1.d_date_sk
JOIN date_dim d_store2
  ON s2.s_closed_date_sk = d_store2.d_date_sk
WHERE w.w_warehouse_sq_ft > (
        SELECT AVG(w2.w_warehouse_sq_ft)
        FROM warehouse w2
        WHERE w2.w_state = w.w_state
      )
  AND d_sold.d_year = 2001
GROUP BY
    ca_bill.ca_state,
    w.w_state,
    d_sold.d_year,
    s1.s_store_name
ORDER BY total_profit DESC
LIMIT 100
