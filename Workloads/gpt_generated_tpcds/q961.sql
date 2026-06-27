WITH monthly_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        i.i_category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date <= DATE '2020-12-31'
    GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, i.i_category
),
monthly_inventory AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        i.i_category,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date <= DATE '2020-12-31'
    GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, i.i_category
),
open_call_centers AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT cc.cc_call_center_sk) AS open_cc_count
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date <= DATE '2020-12-31'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.w_warehouse_name,
    s.i_category,
    s.total_net_paid,
    s.total_quantity,
    s.total_profit,
    i.avg_quantity_on_hand,
    cc.open_cc_count
FROM monthly_sales s
LEFT JOIN monthly_inventory i
    ON s.d_year = i.d_year
    AND s.d_month_seq = i.d_month_seq
    AND s.w_warehouse_name = i.w_warehouse_name
    AND s.i_category = i.i_category
LEFT JOIN open_call_centers cc
    ON s.d_year = cc.d_year
    AND s.d_month_seq = cc.d_month_seq
ORDER BY s.d_year, s.d_month_seq, s.w_warehouse_name, s.i_category
