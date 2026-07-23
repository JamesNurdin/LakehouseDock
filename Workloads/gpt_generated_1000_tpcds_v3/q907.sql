WITH ranked_catalog AS (
    SELECT
        cs.cs_order_number AS order_number,
        p.p_promo_id AS promo_id,
        sm.sm_ship_mode_id AS ship_mode_id,
        cs.cs_net_profit AS net_profit,
        CASE 
            WHEN cs.cs_net_profit > 5000 THEN 'High'
            WHEN cs.cs_net_profit > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ext_discount_amt > 0
      AND sm.sm_carrier = 'AIRBORNE'
      AND sm.sm_code = 'AIR'
)

SELECT DISTINCT source, order_number, promo_id, ship_mode_id, net_profit, profit_category, profit_rank
FROM (
    SELECT
        'catalog' AS source,
        rc.order_number,
        rc.promo_id,
        rc.ship_mode_id,
        rc.net_profit,
        rc.profit_category,
        rc.profit_rank
    FROM ranked_catalog rc
    WHERE rc.profit_rank <= 10

    UNION ALL

    SELECT
        'web' AS source,
        ws.ws_order_number AS order_number,
        p.p_promo_id AS promo_id,
        sm.sm_ship_mode_id AS ship_mode_id,
        ws.ws_net_profit AS net_profit,
        CASE 
            WHEN ws.ws_net_profit > 5000 THEN 'High'
            WHEN ws.ws_net_profit > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ext_discount_amt > 0
      AND sm.sm_carrier = 'AIRBORNE'
      AND sm.sm_code = 'AIR'
) AS combined
ORDER BY net_profit DESC
LIMIT 100
