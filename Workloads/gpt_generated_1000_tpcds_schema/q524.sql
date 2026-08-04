WITH join_all AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        d.d_date,
        d.d_year,
        cc.cc_call_center_id,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        r.r_reason_desc,
        p.p_promo_id,
        s.s_store_id,
        s.s_number_employees,
        s.s_market_manager,
        ws.web_site_id,
        CASE WHEN cr.cr_net_loss > 500 THEN 1 ELSE 0 END AS high_loss_flag,
        RANK() OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_return_amount DESC) AS return_rank
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_current_quarter = 'Y'
      AND p.p_channel_tv = 'N'
      AND s.s_market_manager = 'John Sizemore'
      AND cr.cr_return_tax > 5.0
),
exploded AS (
    SELECT
        ja.*,
        t.val AS metric_value,
        CASE t.idx WHEN 1 THEN 'amount' ELSE 'tax' END AS metric_type
    FROM join_all ja
    CROSS JOIN UNNEST(ARRAY[ja.cr_return_amount, ja.cr_return_tax]) WITH ORDINALITY AS t(val, idx)
),
unioned AS (
    SELECT s_store_id, metric_type, metric_value
    FROM exploded
    WHERE metric_type = 'amount' AND metric_value > 200
    UNION
    SELECT s_store_id, metric_type, metric_value
    FROM exploded
    WHERE metric_type = 'tax' AND metric_value > 10
),
intersected_ids AS (
    SELECT s_store_id FROM unioned
    INTERSECT
    SELECT s_store_id FROM store WHERE s_number_employees > 100
)
SELECT
    ja.s_store_id,
    ja.s_market_manager,
    ja.cc_call_center_id,
    ja.p_promo_id,
    ja.high_loss_flag,
    ja.return_rank,
    e.metric_type,
    e.metric_value
FROM join_all ja
JOIN exploded e ON ja.s_store_id = e.s_store_id
WHERE ja.s_store_id IN (SELECT s_store_id FROM intersected_ids)
ORDER BY ja.return_rank ASC, e.metric_value DESC
LIMIT 100
