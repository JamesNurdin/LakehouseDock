WITH union_data AS (
    SELECT
        sm.sm_type AS ship_mode,
        td.t_hour AS hour_of_day,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE td.t_meal_time = 'dinner'
      AND cs.cs_quantity > 1
      AND EXISTS (
          SELECT 1
          FROM item i2
          WHERE i2.i_category = i.i_category
            AND i2.i_current_price > 50
      )
    GROUP BY sm.sm_type, td.t_hour
    UNION ALL
    SELECT
        sm.sm_type AS ship_mode,
        td.t_hour AS hour_of_day,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE td.t_meal_time = 'dinner'
      AND ws.ws_quantity > 1
      AND EXISTS (
          SELECT 1
          FROM web_site ws2
          WHERE ws2.web_state = ws_site.web_state
            AND ws2.web_tax_percentage > 5
      )
    GROUP BY sm.sm_type, td.t_hour
)
SELECT
    u.ship_mode,
    u.hour_of_day,
    u.total_profit,
    u.order_cnt,
    u.profit_level,
    (SELECT AVG(net_profit) FROM (
        SELECT cs.cs_net_profit AS net_profit FROM catalog_sales cs
        UNION ALL
        SELECT ws.ws_net_profit AS net_profit FROM web_sales ws
    ) AS all_profits) AS avg_overall_profit
FROM union_data u
ORDER BY u.total_profit DESC
LIMIT 100
