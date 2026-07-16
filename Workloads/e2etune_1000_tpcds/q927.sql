WITH agg AS (
    SELECT
        cc.cc_state,
        w.w_city,
        p.p_promo_name,
        sm.sm_type,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cr.cr_item_sk = p.p_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state IN ('TN', 'GA', 'MI')
      AND cc.cc_mkt_id IN (2, 3, 5)
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND p.p_channel_email = 'Y'
      AND sm.sm_type = 'AIR'
      AND hd.hd_vehicle_count > 0
    GROUP BY cc.cc_state, w.w_city, p.p_promo_name, sm.sm_type
    HAVING SUM(cr.cr_return_amount) > 10000
)
SELECT
    agg.cc_state,
    agg.w_city,
    agg.p_promo_name,
    agg.sm_type,
    agg.return_cnt,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.avg_return_qty,
    agg.avg_vehicle_count,
    agg.total_return_amount / NULLIF(agg.total_net_loss, 0) AS loss_to_return_ratio,
    RANK() OVER (ORDER BY agg.total_return_amount DESC) AS return_rank
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
