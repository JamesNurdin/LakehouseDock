WITH cr_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_amt_inc_tax < 5000
      AND cr.cr_refunded_cash > 0
      AND cr.cr_fee >= 0
    GROUP BY cr.cr_warehouse_sk, cr.cr_ship_mode_sk
),
distinct_ship_modes AS (
    SELECT DISTINCT sm.sm_ship_mode_sk, sm.sm_ship_mode_id, sm.sm_type
    FROM ship_mode sm
    WHERE sm.sm_type IN ('AIR', 'RAIL')
)
SELECT DISTINCT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    dsm.sm_ship_mode_id,
    cr_agg.return_cnt,
    cr_agg.total_return_amount,
    ws.ws_order_number,
    ws.ws_wholesale_cost,
    ws.ws_net_paid,
    ws.ws_net_profit,
    RANK() OVER (PARTITION BY w.w_state ORDER BY cr_agg.total_return_amount DESC) AS state_return_rank,
    (
        SELECT SUM(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
    ) AS warehouse_total_net_paid
FROM cr_agg
JOIN distinct_ship_modes dsm
    ON cr_agg.cr_ship_mode_sk = dsm.sm_ship_mode_sk
JOIN warehouse w
    ON cr_agg.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = dsm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_wholesale_cost BETWEEN 10 AND 60
  AND ws.ws_ship_date_sk >= 2452200
  AND ws.ws_ship_date_sk <= 2452300
  AND w.w_state = 'CA'
  AND w.w_warehouse_sq_ft > 50000
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number
          AND ws2.ws_net_profit > 1000
    )
ORDER BY state_return_rank, w.w_warehouse_id
LIMIT 100
