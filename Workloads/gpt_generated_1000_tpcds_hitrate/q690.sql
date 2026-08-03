WITH combined_sales AS (
    SELECT
        'catalog' AS sale_type,
        i.i_category AS item_category,
        sm.sm_carrier AS ship_carrier,
        cs.cs_net_paid_inc_ship_tax AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND cs.cs_net_paid_inc_ship_tax > 0
    UNION ALL
    SELECT
        'web' AS sale_type,
        i.i_category AS item_category,
        sm.sm_carrier AS ship_carrier,
        ws.ws_net_paid_inc_ship_tax AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND ws.ws_net_paid_inc_ship_tax > 0
),
aggregated AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SUM(net_paid) DESC) AS row_num,
        sale_type,
        item_category,
        ship_carrier,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        CASE WHEN SUM(net_profit) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM combined_sales
    GROUP BY ROLLUP (sale_type, item_category, ship_carrier)
)
SELECT
    a.row_num,
    a.sale_type,
    a.item_category,
    a.ship_carrier,
    a.total_net_paid,
    a.total_net_profit,
    a.profit_flag,
    d.dim_carrier
FROM aggregated a
CROSS JOIN (
    SELECT DISTINCT sm.sm_carrier AS dim_carrier
    FROM ship_mode sm
    WHERE sm.sm_carrier IN ('DHL', 'BOXBUNDLES')
) d
LIMIT 100
