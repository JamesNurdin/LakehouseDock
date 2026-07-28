WITH item_returns AS (
    SELECT
        cr.cr_item_sk,
        i.i_item_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_shift = 'first'
      AND i.i_units = 'Each'
      AND sm.sm_carrier = 'UPS'
    GROUP BY cr.cr_item_sk, i.i_item_id
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    ir.i_item_id,
    ir.total_return_amount,
    ir.total_net_loss,
    ir.return_cnt,
    COALESCE(ws.ws_total_sales, 0) AS ws_total_sales,
    COALESCE(ws.ws_total_profit, 0) AS ws_total_profit,
    RANK() OVER (ORDER BY ir.total_net_loss DESC) AS net_loss_rank,
    CASE WHEN ws.ws_total_sales > 0 THEN 'Has Sales' ELSE 'No Sales' END AS sales_flag
FROM item_returns ir
LEFT JOIN (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS ws_total_sales,
        SUM(ws.ws_net_profit) AS ws_total_profit
    FROM web_sales ws
    JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
    WHERE td2.t_am_pm = 'PM'
      AND ws.ws_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = ws.ws_ship_mode_sk
            AND sm2.sm_carrier = 'UPS'
      )
    GROUP BY ws.ws_item_sk
) ws ON ir.cr_item_sk = ws.ws_item_sk
ORDER BY net_loss_rank
LIMIT 100
