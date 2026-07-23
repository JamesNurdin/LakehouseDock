WITH base_join AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_net_loss,
        sm.sm_code,
        w.w_gmt_offset,
        t.t_hour,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        s.s_store_id,
        s.s_state,
        c.c_last_review_date
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        sm.sm_code IN ('AIR', 'SEA')
        AND w.w_gmt_offset = -5.00
        AND s.s_state = 'CA'
        AND t.t_hour BETWEEN 9 AND 17
        AND c.c_last_review_date > 2452400
),
agg_data AS (
    SELECT
        s_store_id,
        sm_code,
        t_hour,
        SUM(cr_return_quantity + sr_return_quantity) AS total_return_quantity,
        SUM(cr_net_loss + sr_net_loss) AS total_net_loss
    FROM base_join
    GROUP BY
        s_store_id,
        sm_code,
        t_hour
)
SELECT
    s_store_id,
    sm_code,
    t_hour,
    total_return_quantity,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY sm_code ORDER BY total_net_loss DESC) AS loss_rank_per_ship_mode,
    SUM(total_net_loss) OVER (PARTITION BY sm_code ORDER BY t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_loss_by_hour
FROM agg_data
ORDER BY
    sm_code,
    loss_rank_per_ship_mode
