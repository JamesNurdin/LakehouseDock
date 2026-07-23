WITH cs_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_net_paid) AS cs_total_net_paid,
        SUM(cs.cs_net_profit) AS cs_total_net_profit,
        COUNT(*) AS cs_sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 1000
      AND cs.cs_quantity >= 5
    GROUP BY cs.cs_ship_mode_sk, cs.cs_promo_sk
),
ws_agg AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_net_paid) AS ws_total_net_paid,
        SUM(ws.ws_net_profit) AS ws_total_net_profit,
        COUNT(*) AS ws_sales_cnt
    FROM web_sales ws
    WHERE ws.ws_net_paid > 1000
      AND ws.ws_quantity >= 5
    GROUP BY ws.ws_ship_mode_sk, ws.ws_promo_sk
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_code,
    p.p_promo_id,
    p.p_purpose,
    cs_agg.cs_total_net_paid,
    ws_agg.ws_total_net_paid,
    (cs_agg.cs_total_net_paid + ws_agg.ws_total_net_paid) AS total_net_paid,
    cs_agg.cs_total_net_profit,
    ws_agg.ws_total_net_profit,
    (cs_agg.cs_total_net_profit + ws_agg.ws_total_net_profit) AS total_net_profit,
    (cs_agg.cs_sales_cnt + ws_agg.ws_sales_cnt) AS total_sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY (cs_agg.cs_total_net_paid + ws_agg.ws_total_net_paid) DESC) AS rank_by_net_paid
FROM cs_agg
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN ws_agg
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws_agg.ws_promo_sk = p.p_promo_sk
WHERE sm.sm_code IN ('AIR', 'SEA')
  AND p.p_purpose = 'Unknown'
  AND p.p_channel_event = 'N'
ORDER BY total_net_paid DESC
LIMIT 100
