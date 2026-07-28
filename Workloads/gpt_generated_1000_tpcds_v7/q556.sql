WITH combined AS (
    SELECT
        I.i_item_id,
        D.d_year,
        D.d_month_seq,
        (COALESCE(C.cr_net_loss, 0) + COALESCE(SR.sr_net_loss, 0) + COALESCE(WR.wr_net_loss, 0)) AS total_loss
    FROM catalog_returns C
    JOIN date_dim D ON C.cr_returned_date_sk = D.d_date_sk
    JOIN time_dim T ON C.cr_returned_time_sk = T.t_time_sk
    JOIN item I ON C.cr_item_sk = I.i_item_sk
    JOIN promotion P ON P.p_item_sk = I.i_item_sk
    JOIN ship_mode SM ON C.cr_ship_mode_sk = SM.sm_ship_mode_sk
    JOIN warehouse W ON C.cr_warehouse_sk = W.w_warehouse_sk
    JOIN reason R ON C.cr_reason_sk = R.r_reason_sk
    LEFT JOIN store_returns SR ON SR.sr_item_sk = I.i_item_sk
                               AND SR.sr_returned_date_sk = D.d_date_sk
                               AND SR.sr_return_time_sk = T.t_time_sk
    LEFT JOIN web_returns WR ON WR.wr_item_sk = I.i_item_sk
                              AND WR.wr_returned_date_sk = D.d_date_sk
                              AND WR.wr_returned_time_sk = T.t_time_sk
    WHERE D.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND I.i_current_price > 50
      AND P.p_discount_active = 'Y'
      AND SM.sm_type = 'AIR'
      AND W.w_state = 'CA'
      AND R.r_reason_desc LIKE '%damaged%'
)
SELECT
    i_item_id,
    AVG(total_loss) AS avg_monthly_loss,
    SUM(total_loss) AS sum_loss,
    COUNT(*) AS months_reported
FROM combined
GROUP BY i_item_id
HAVING AVG(total_loss) > 1000
ORDER BY avg_monthly_loss DESC
LIMIT 100
