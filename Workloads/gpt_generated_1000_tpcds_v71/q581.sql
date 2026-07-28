WITH filtered_warehouses AS (
    SELECT w_warehouse_sk,
           w_state,
           w_city,
           w_warehouse_sq_ft
    FROM   warehouse
    WHERE  w_state IN ('CA', 'TX')
)
SELECT src,
       w_warehouse_sk,
       w_state,
       ship_mode,
       metric_amount,
       metric_cnt
FROM (
    SELECT 'RETURN' AS src,
           cw.w_warehouse_sk,
           cw.w_state,
           sm.sm_type AS ship_mode,
           SUM(cr.cr_return_amount) AS metric_amount,
           COUNT(*) AS metric_cnt
    FROM   catalog_returns cr
    JOIN   filtered_warehouses cw
           ON cr.cr_warehouse_sk = cw.w_warehouse_sk
    JOIN   ship_mode sm
           ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE  sm.sm_type = 'EXPRESS'
    GROUP BY cw.w_warehouse_sk,
             cw.w_state,
             sm.sm_type
    HAVING SUM(cr.cr_return_amount) > 10000

    UNION ALL

    SELECT 'WEB_SALE' AS src,
           cw.w_warehouse_sk,
           cw.w_state,
           sm.sm_type AS ship_mode,
           SUM(ws.ws_net_profit) AS metric_amount,
           COUNT(*) AS metric_cnt
    FROM   web_sales ws
    JOIN   filtered_warehouses cw
           ON ws.ws_warehouse_sk = cw.w_warehouse_sk
    JOIN   ship_mode sm
           ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE  NOT EXISTS (
               SELECT 1
               FROM   promotion p
               WHERE  p.p_promo_sk = ws.ws_promo_sk
                  AND p.p_discount_active = 'Y'
           )
      AND sm.sm_type = 'NEXT DAY'
    GROUP BY cw.w_warehouse_sk,
             cw.w_state,
             sm.sm_type
    HAVING SUM(ws.ws_net_profit) > 5000
) AS combined
ORDER BY src,
         metric_amount DESC
LIMIT 100
