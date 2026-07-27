/*
Goal: Calculate total web sales and average profit by warehouse, shipping mode, month and customer gender for the year 2001, filtering to preferred customers, UPS shipments, California warehouses, business‑hour sales, and dates where inventory on hand exceeds 500 units. Show only groups with sales over 1,000,000, include the maximum inventory quantity per warehouse, and order the result by total sales descending.
*/
WITH base AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number,
        d.d_month_seq,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        sm.sm_type,
        cd.cd_gender,
        d.d_date,
        d.d_year,
        t.t_hour,
        sm.sm_carrier,
        w.w_state,
        c.c_preferred_cust_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
                     AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND t.t_hour BETWEEN 9 AND 17
      AND sm.sm_carrier = 'UPS'
      AND w.w_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND EXISTS (
          SELECT 1
          FROM inventory inv_sub
          WHERE inv_sub.inv_date_sk = d.d_date_sk
            AND inv_sub.inv_quantity_on_hand > 500
      )
)
SELECT
    w_warehouse_name,
    sm_type,
    d_month_seq,
    cd_gender,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    (
        SELECT MAX(inv_quantity_on_hand)
        FROM inventory inv_max
        WHERE inv_max.inv_warehouse_sk = base.w_warehouse_sk
    ) AS max_inventory_qty
FROM base
GROUP BY w_warehouse_name, sm_type, d_month_seq, cd_gender, w_warehouse_sk
HAVING SUM(ws_ext_sales_price) > 1000000
ORDER BY total_sales DESC
LIMIT 100
