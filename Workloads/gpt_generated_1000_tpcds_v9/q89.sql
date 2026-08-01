WITH distinct_carriers AS (
    SELECT DISTINCT sm_carrier
    FROM ship_mode
    WHERE sm_carrier IN ('USPS', 'DIAMOND', 'ALLIANCE')
)
SELECT
    sales_channel,
    sm_carrier,
    d_year,
    total_net_profit,
    total_quantity,
    distinct_orders,
    avg_catalog_profit
FROM (
    SELECT
        'catalog' AS sales_channel,
        sm.sm_carrier AS sm_carrier,
        d.d_year AS d_year,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_profit > 0
        AND d.d_year BETWEEN 1999 AND 2001
        AND sm.sm_carrier IN (SELECT sm_carrier FROM distinct_carriers)
        AND NOT EXISTS (
            SELECT 1 FROM store s WHERE s.s_closed_date_sk = d.d_date_sk
        )
    GROUP BY GROUPING SETS (
        (sm.sm_carrier, d.d_year),
        (sm.sm_carrier),
        (d.d_year),
        ()
    )
    UNION ALL
    SELECT
        'web' AS sales_channel,
        sm.sm_carrier AS sm_carrier,
        d.d_year AS d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_catalog_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_net_profit > 0
        AND d.d_year BETWEEN 1999 AND 2001
        AND sm.sm_carrier IN (SELECT sm_carrier FROM distinct_carriers)
        AND NOT EXISTS (
            SELECT 1 FROM store s WHERE s.s_closed_date_sk = d.d_date_sk
        )
    GROUP BY GROUPING SETS (
        (sm.sm_carrier, d.d_year),
        (sm.sm_carrier),
        (d.d_year),
        ()
    )
) AS combined
ORDER BY sales_channel, sm_carrier, d_year
LIMIT 100
