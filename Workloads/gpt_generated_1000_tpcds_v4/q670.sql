WITH inventory_summary AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    d.d_year,
    s.s_state,
    sm.sm_type,
    w.w_warehouse_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_ws_net_paid,
    AVG(ws.ws_net_profit) AS avg_ws_net_profit,
    SUM(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_net_profit ELSE 0 END) AS profit_positive,
    SUM(CASE WHEN ws.ws_net_profit <= 0 THEN ws.ws_net_profit ELSE 0 END) AS profit_negative,
    SUM(ss.ss_net_paid) AS total_ss_net_paid,
    inventory_summary.total_qty
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d.d_date_sk
JOIN inventory_summary
  ON inventory_summary.inv_warehouse_sk = w.w_warehouse_sk
  AND inventory_summary.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND s.s_state = 'CA'
  AND w.w_state = 'WA'
  AND sm.sm_type = 'AIR'
  AND cp.cp_department = 'Electronics'
  AND wp.wp_type = 'Content'
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
          AND i.inv_date_sk = d.d_date_sk
          AND i.inv_quantity_on_hand > 100
      )
GROUP BY d.d_year, s.s_state, sm.sm_type, w.w_warehouse_name, inventory_summary.total_qty
ORDER BY total_ws_net_paid DESC
LIMIT 100
