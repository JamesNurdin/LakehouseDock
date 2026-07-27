WITH sales_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS ship_mode_type,
        d_sold.d_year AS sales_year,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_qty,
        AVG(ws.ws_net_profit) AS avg_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH'
            WHEN SUM(ws.ws_net_profit) > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_sold.d_year = 2001
      AND ws_site.web_gmt_offset = -6.00
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
      AND ws.ws_net_profit > 0
      AND ws_site.web_mkt_class LIKE '%New%'
    GROUP BY w.w_warehouse_name, sm.sm_type, d_sold.d_year
)
SELECT
    warehouse_name,
    profit_category,
    total_profit,
    total_qty,
    avg_profit,
    CASE
        WHEN total_profit > (SELECT AVG(total_profit) FROM sales_agg) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_vs_avg
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
