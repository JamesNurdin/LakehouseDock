WITH sales_agg AS (
    SELECT
        w.w_warehouse_name,
        'Q' || CAST(d_ship.d_fy_quarter_seq AS VARCHAR) AS fiscal_quarter,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM web_sales ws
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
        AND wr.wr_returned_date_sk = d_ship.d_date_sk
    LEFT JOIN inventory inv
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
        AND d_ship.d_date_sk = inv.inv_date_sk
    WHERE d_ship.d_fy_year = 1904
    GROUP BY w.w_warehouse_name, d_ship.d_fy_quarter_seq
)
SELECT
    w_warehouse_name,
    fiscal_quarter,
    total_net_profit,
    total_quantity_sold,
    total_return_quantity,
    CASE WHEN total_quantity_sold = 0 THEN 0
         ELSE total_return_quantity * 100.0 / total_quantity_sold
    END AS return_rate_pct,
    avg_inventory_on_hand,
    RANK() OVER (PARTITION BY fiscal_quarter ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY fiscal_quarter, profit_rank
