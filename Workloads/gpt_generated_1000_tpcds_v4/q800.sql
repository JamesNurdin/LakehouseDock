WITH sales_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ca.ca_state,
        cc.cc_state,
        sm.sm_type,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ws.ws_net_paid,
        inv.inv_quantity_on_hand,
        ss.ss_sales_price,
        ws.ws_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON d.d_date_sk = cc.cc_closed_date_sk
    JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'TX'
      AND ca.ca_location_type = 'single family'
      AND inv.inv_quantity_on_hand > 500
      AND t.t_hour BETWEEN 9 AND 17
      AND sm.sm_type = 'AIR'
)
SELECT
    d_year,
    d_month_seq,
    ca_state,
    cc_state,
    sm_type,
    COUNT(DISTINCT ss_ticket_number) AS cnt_orders,
    SUM(ss_net_paid) AS total_store_net_paid,
    SUM(ws_net_paid) AS total_web_net_paid,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    MAX(ss_sales_price) AS max_store_sales_price,
    MAX(ws_sales_price) AS max_web_sales_price
FROM sales_data
GROUP BY
    d_year,
    d_month_seq,
    ca_state,
    cc_state,
    sm_type
ORDER BY total_store_net_paid DESC
LIMIT 100
