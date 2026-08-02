WITH agg_returns AS (
    SELECT 
        cc.cc_company_name,
        cc.cc_state,
        COALESCE(sm.sm_type, 'UNKNOWN') AS ship_mode_type,
        i.i_brand_id,
        i.i_item_sk,
        t.t_hour,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        MIN(cr.cr_return_amount) AS min_return_amount,
        MAX(cr.cr_return_amount) AS max_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE 
        cc.cc_company_name = 'cally'
        AND i.i_brand_id = 5002002
        AND hd_ref.hd_buy_potential = '>10000'
        AND t.t_hour BETWEEN 9 AND 17
        AND NOT EXISTS (
            SELECT 1 FROM reason r2 
            WHERE r2.r_reason_sk = cr.cr_reason_sk 
              AND r2.r_reason_desc = 'Damaged'
        )
    GROUP BY 
        cc.cc_company_name,
        cc.cc_state,
        sm.sm_type,
        i.i_brand_id,
        i.i_item_sk,
        t.t_hour
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT 
    ar.cc_company_name,
    ar.cc_state,
    ar.ship_mode_type,
    ar.i_brand_id,
    ar.t_hour,
    ar.return_cnt,
    ar.total_return_amount,
    ar.avg_return_tax,
    ar.min_return_amount,
    ar.max_return_amount,
    ar.total_net_loss,
    SUM(ar.total_net_loss) OVER (PARTITION BY ar.cc_company_name ORDER BY ar.t_hour ROWS UNBOUNDED PRECEDING) AS running_net_loss_by_company,
    (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = ar.i_item_sk) AS max_item_return_amount
FROM agg_returns ar
WHERE ar.i_brand_id NOT IN (
    SELECT i2.i_brand_id FROM item i2 WHERE i2.i_units = 'Unknown'
)
ORDER BY ar.total_net_loss DESC
LIMIT 100
