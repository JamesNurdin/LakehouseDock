WITH joined_data AS (
    SELECT
        r_cr.r_reason_desc      AS reason_desc,
        cc.cc_name               AS call_center_name,
        sm.sm_type               AS ship_mode_type,
        cr.cr_net_loss           AS cr_net_loss,
        sr.sr_net_loss           AS sr_net_loss,
        wr.wr_net_loss           AS wr_net_loss,
        cr.cr_order_number       AS cr_order_number,
        sr.sr_ticket_number      AS sr_ticket_number,
        wr.wr_order_number       AS wr_order_number
    FROM catalog_returns cr
    JOIN call_center   cc   ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode     sm   ON cr.cr_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse     w_cr ON cr.cr_warehouse_sk   = w_cr.w_warehouse_sk
    JOIN reason        r_cr ON cr.cr_reason_sk      = r_cr.r_reason_sk
    JOIN date_dim      d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk

    JOIN store_returns sr ON TRUE
    JOIN date_dim      d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN reason        r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk

    JOIN web_returns   wr   ON TRUE
    JOIN date_dim      d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN reason        r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk

    JOIN inventory      i    ON TRUE
    JOIN date_dim       d_inv ON i.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse      w_inv ON i.inv_warehouse_sk = w_inv.w_warehouse_sk

    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open   ON cc.cc_open_date_sk   = d_cc_open.d_date_sk

    WHERE d_cr.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_warehouse_sk = w_cr.w_warehouse_sk
            AND i2.inv_quantity_on_hand > 0
      )
)
SELECT
    reason_desc,
    call_center_name,
    ship_mode_type,
    SUM(cr_net_loss + sr_net_loss + wr_net_loss)                     AS total_net_loss,
    COUNT(DISTINCT cr_order_number)                                   AS catalog_orders,
    COUNT(DISTINCT sr_ticket_number)                                  AS store_tickets,
    COUNT(DISTINCT wr_order_number)                                   AS web_orders,
    (SELECT MAX(inv_quantity_on_hand) FROM inventory)               AS max_inventory_overall,
    RANK() OVER (ORDER BY SUM(cr_net_loss + sr_net_loss + wr_net_loss) DESC) AS loss_rank
FROM joined_data
GROUP BY reason_desc, call_center_name, ship_mode_type
ORDER BY total_net_loss DESC, loss_rank
LIMIT 100
