WITH catalog_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        SUM(cs.cs_net_profit) AS total_net_profit,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_quantity > 2
    GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count
),
web_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        'web' AS source
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
      AND ws.ws_ext_tax > 20.0
    GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_net_profit DESC
LIMIT 100
