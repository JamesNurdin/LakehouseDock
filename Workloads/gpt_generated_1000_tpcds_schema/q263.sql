WITH catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        sm.sm_type AS ship_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN i.i_wholesale_cost > 20 THEN 'high' ELSE 'low' END AS cost_category
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY i.i_item_id, i.i_item_desc, sm.sm_type, i.i_wholesale_cost
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        sm.sm_type AS ship_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        CASE WHEN i.i_wholesale_cost > 20 THEN 'high' ELSE 'low' END AS cost_category
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY i.i_item_id, i.i_item_desc, sm.sm_type, i.i_wholesale_cost
)
SELECT
    i_item_id,
    i_item_desc,
    ship_type,
    total_net_profit,
    cost_category
FROM catalog_agg
UNION ALL
SELECT
    i_item_id,
    i_item_desc,
    ship_type,
    total_net_profit,
    cost_category
FROM web_agg
ORDER BY total_net_profit DESC
LIMIT 100
