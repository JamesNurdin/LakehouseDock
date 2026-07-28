WITH joined_data AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        r.r_reason_desc,
        td.t_hour,
        i.i_item_id,
        sm.sm_ship_mode_id,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(cr.cr_return_quantity) AS return_qty,
        SUM(ws.ws_net_paid) AS total_sales_paid,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit'
            WHEN SUM(ws.ws_net_profit) < 0 THEN 'Loss'
            ELSE 'Zero'
        END AS profit_indicator
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    WHERE r.r_reason_desc = 'Gift exchange'
      AND i.i_wholesale_cost > 1.00
      AND td.t_hour BETWEEN 9 AND 17
      AND (cc.cc_state = 'CA' OR cc.cc_state IS NULL)
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_state,
        r.r_reason_desc,
        td.t_hour,
        i.i_item_id,
        sm.sm_ship_mode_id
)
SELECT
    cc_call_center_id,
    cc_state,
    r_reason_desc,
    t_hour,
    total_return_loss,
    total_sales_paid,
    profit_indicator,
    total_return_loss / NULLIF(total_sales_paid, 0) AS loss_to_sales_ratio
FROM joined_data
WHERE total_return_loss > 1000
ORDER BY loss_to_sales_ratio DESC NULLS LAST
LIMIT 100
