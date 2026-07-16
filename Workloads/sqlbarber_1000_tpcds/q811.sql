SELECT
    sm.sm_ship_mode_id,
    cs_agg.cs_net_paid_sum,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM (
    SELECT cs.cs_ship_mode_sk,
           SUM(cs.cs_net_paid) AS cs_net_paid_sum
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk = 2450835
    GROUP BY cs.cs_ship_mode_sk
) cs_agg
JOIN ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY sm.sm_ship_mode_id, cs_agg.cs_net_paid_sum
HAVING SUM(cr.cr_return_amount) > 405.60
