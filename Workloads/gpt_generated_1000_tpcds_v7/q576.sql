WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_class,
        cc.cc_country,
        w.w_warehouse_id,
        w.w_state,
        w.w_warehouse_sq_ft,
        t.t_hour,
        cd.cd_gender,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss AS sr_net_loss
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
       AND sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_class IN ('large', 'medium')
      AND cc.cc_country = 'United States'
      AND t.t_hour BETWEEN 8 AND 17
      AND w.w_state IN ('IN', 'TN')
      AND cd.cd_gender = 'M'
      AND cr.cr_return_amount > 100
      AND w.w_warehouse_sq_ft > 1000000
),
agg_per_hour AS (
    SELECT
        cc_call_center_id,
        t_hour,
        SUM(cr_net_loss + sr_net_loss) AS total_net_loss
    FROM base
    GROUP BY cc_call_center_id, t_hour
)
SELECT
    cc_call_center_id,
    AVG(total_net_loss) AS avg_total_net_loss,
    COUNT(DISTINCT t_hour) AS hours_covered
FROM agg_per_hour
GROUP BY cc_call_center_id
HAVING AVG(total_net_loss) > 5000
ORDER BY avg_total_net_loss DESC
LIMIT 10
