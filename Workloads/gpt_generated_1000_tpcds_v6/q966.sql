SELECT
    ws.ws_order_number,
    cd.cd_gender,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    ws.ws_ext_ship_cost,
    ws.ws_net_paid_inc_ship_tax,
    ws.ws_quantity,
    ws.ws_net_profit,
    CASE
        WHEN ws.ws_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_flag,
    RANK() OVER (PARTITION BY sm.sm_type ORDER BY ws.ws_net_paid_inc_ship_tax DESC) AS rank_by_revenue,
    SUM(ws.ws_net_profit) OVER (PARTITION BY cd.cd_gender ORDER BY ws.ws_order_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_gender
FROM tpcds.web_sales ws
JOIN tpcds.customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_ext_ship_cost > 150
  AND ws.ws_quantity >= 2
  AND p.p_response_target = 1
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_fee > 30
    )
ORDER BY rank_by_revenue
LIMIT 100
