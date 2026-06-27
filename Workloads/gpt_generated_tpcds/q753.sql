WITH catalog_sales_agg AS (
    SELECT cs.cs_call_center_sk,
           cs.cs_warehouse_sk,
           cs.cs_ship_mode_sk,
           SUM(cs.cs_net_paid)   AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk,
             cs.cs_warehouse_sk,
             cs.cs_ship_mode_sk
),
catalog_returns_agg AS (
    SELECT cr.cr_call_center_sk,
           cr.cr_warehouse_sk,
           cr.cr_ship_mode_sk,
           SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk,
             cr.cr_warehouse_sk,
             cr.cr_ship_mode_sk
),
combined AS (
    SELECT COALESCE(cs.cs_call_center_sk, cr.cr_call_center_sk) AS call_center_sk,
           COALESCE(cs.cs_warehouse_sk,   cr.cr_warehouse_sk)   AS warehouse_sk,
           COALESCE(cs.cs_ship_mode_sk,  cr.cr_ship_mode_sk)  AS ship_mode_sk,
           cs.total_sales,
           cs.total_profit,
           cr.total_loss
    FROM catalog_sales_agg cs
    FULL OUTER JOIN catalog_returns_agg cr
      ON cs.cs_call_center_sk = cr.cr_call_center_sk
     AND cs.cs_warehouse_sk   = cr.cr_warehouse_sk
     AND cs.cs_ship_mode_sk   = cr.cr_ship_mode_sk
)
SELECT cc.cc_call_center_id,
       w.w_warehouse_name,
       sm.sm_ship_mode_id,
       COALESCE(comb.total_sales, 0)  AS total_sales,
       COALESCE(comb.total_profit, 0) AS total_profit,
       COALESCE(comb.total_loss, 0)   AS total_loss,
       COALESCE(comb.total_profit, 0) - COALESCE(comb.total_loss, 0) AS net_contribution
FROM combined comb
LEFT JOIN call_center cc ON comb.call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse    w  ON comb.warehouse_sk   = w.w_warehouse_sk
LEFT JOIN ship_mode    sm ON comb.ship_mode_sk   = sm.sm_ship_mode_sk
ORDER BY net_contribution DESC
LIMIT 100
