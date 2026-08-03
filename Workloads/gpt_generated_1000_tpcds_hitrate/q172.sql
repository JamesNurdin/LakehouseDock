WITH joined AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        r.r_reason_desc,
        td.t_hour,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_hour BETWEEN 12 AND 18
      AND r.r_reason_id = 'AAAAAAAACBAAAAAA'
      AND cc.cc_country = 'United States'
      AND w.w_state = 'CA'
),
agg_returns AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        w_warehouse_sk,
        w_warehouse_name,
        loss_category,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM joined
    GROUP BY
        cc_call_center_sk,
        cc_name,
        w_warehouse_sk,
        w_warehouse_name,
        loss_category
)
SELECT
    cc_name,
    w_warehouse_name,
    loss_category,
    total_net_loss,
    return_cnt,
    CASE WHEN total_net_loss > (SELECT AVG(total_net_loss) FROM agg_returns) THEN 'Above Avg' ELSE 'Below Avg' END AS avg_comparison
FROM agg_returns
WHERE total_net_loss > (SELECT AVG(total_net_loss) FROM agg_returns)
ORDER BY total_net_loss DESC
LIMIT 100
