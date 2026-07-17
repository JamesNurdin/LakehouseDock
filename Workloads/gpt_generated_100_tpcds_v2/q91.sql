WITH sales_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND ca.ca_state IN ('WA', 'AL')
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, ca.ca_state
), inventory_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 500
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
)
SELECT
    s.w_warehouse_id,
    s.w_warehouse_name,
    s.ca_state,
    s.total_net_profit,
    s.total_quantity_sold,
    i.total_inventory_on_hand
FROM sales_agg s
JOIN inventory_agg i ON s.w_warehouse_id = i.w_warehouse_id
ORDER BY s.total_net_profit DESC
