WITH joined AS (
    SELECT
        r_cr.r_reason_desc      AS cr_reason_desc,
        sm_cr.sm_type           AS cr_ship_type,
        cr.cr_net_loss,
        ws.ws_net_profit,
        ss.ss_net_profit,
        cr.cr_return_amount,
        ws.ws_quantity,
        ss.ss_quantity,
        sr.sr_return_tax,
        wp.wp_char_count,
        t.t_am_pm
    FROM catalog_returns cr
    JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cr          ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN warehouse w_cr          ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN reason r_cr              ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN time_dim t               ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws            ON ws.ws_warehouse_sk = w_cr.w_warehouse_sk
    JOIN ship_mode sm_ws          ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t_ws            ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN store_returns sr        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r_sr              ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN store_sales ss          ON ss.ss_item_sk = sr.sr_item_sk
                                 AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN time_dim t_ss            ON ss.ss_sold_time_sk = t_ss.t_time_sk
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_net_loss > 0
      AND ws.ws_net_profit > 0
      AND sr.sr_return_tax > 5
      AND wp.wp_char_count BETWEEN 1000 AND 5000
      AND t.t_am_pm = 'PM'
),
agg AS (
    SELECT
        cr_reason_desc,
        cr_ship_type,
        SUM(cr_net_loss)   AS total_return_loss,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(ss_net_profit) AS total_store_profit
    FROM joined
    GROUP BY ROLLUP (cr_reason_desc, cr_ship_type)
    HAVING SUM(cr_net_loss) > 0
)
SELECT
    COALESCE(cr_reason_desc, 'All Reasons') AS reason_desc,
    COALESCE(cr_ship_type, 'All Ship Types') AS ship_type,
    total_return_loss,
    total_web_profit,
    total_store_profit,
    RANK() OVER (ORDER BY total_return_loss DESC) AS loss_rank
FROM agg
ORDER BY loss_rank, reason_desc
LIMIT 100
