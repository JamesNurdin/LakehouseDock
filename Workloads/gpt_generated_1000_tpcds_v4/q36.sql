WITH ws AS (
    SELECT
        w.w_warehouse_sk,
        w.w_county,
        w.w_city,
        w.w_zip,
        w.w_gmt_offset,
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_type,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_net_paid_inc_ship_tax,
        cc.cc_name
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(sm.sm_ship_mode_id, '^AAAAAAA[AE].*')
      AND w.w_county LIKE '%County'
      AND substr(w.w_zip, 1, 2) = '56'
)
SELECT
    ws.w_county,
    ws.sm_type,
    COUNT(DISTINCT ws.cc_name) AS distinct_call_centers,
    SUM(ws.cs_net_paid) AS total_net_paid,
    SUM(ws.cs_net_profit) AS total_net_profit,
    AVG(ws.cs_coupon_amt) AS avg_coupon_amount,
    CASE
        WHEN SUM(ws.cs_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(ws.cs_net_profit) > 0    THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (
        SELECT MAX(cs2.cs_net_paid_inc_ship_tax)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = ws.w_warehouse_sk
          AND cs2.cs_ship_mode_sk = ws.sm_ship_mode_sk
    ) AS max_net_paid_inc_tax
FROM ws
GROUP BY
    ws.w_county,
    ws.sm_type,
    ws.w_warehouse_sk,
    ws.sm_ship_mode_sk
ORDER BY total_net_paid DESC
LIMIT 100
