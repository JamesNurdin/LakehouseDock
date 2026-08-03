WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
),
joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_order_number,
        dd.d_year,
        dd.d_current_week,
        dd.d_same_day_lq,
        td.t_hour,
        cd.cd_credit_rating,
        cd.cd_dep_college_count,
        hd.hd_income_band_sk,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        rs.r_reason_desc,
        dd.d_date_sk AS date_sk,
        cd.cd_demo_sk AS demo_sk
    FROM base cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason rs ON cr.cr_reason_sk = rs.r_reason_sk
    JOIN promotion p ON dd.d_date_sk = p.p_start_date_sk
    WHERE
        dd.d_year = 2001
        AND dd.d_current_week = 'N'
        AND dd.d_same_day_lq = 2414930
        AND td.t_hour BETWEEN 9 AND 17
        AND cd.cd_credit_rating = 'Good'
        AND cd.cd_dep_college_count >= 4
        AND sm.sm_contract = 'GNJr3g5i7oorKqtX'
)
SELECT
    d_year,
    sm_ship_mode_id,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    MAX(cr_net_loss) AS max_net_loss,
    CASE WHEN SUM(cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS amount_category,
    (SELECT SUM(p_cost) FROM promotion p2 WHERE p2.p_start_date_sk = joined.date_sk) AS promo_cost_for_day,
    (SELECT COUNT(*) FROM catalog_returns cr3 WHERE cr3.cr_refunded_cdemo_sk = joined.demo_sk) AS refunded_demo_return_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cr_return_amount) DESC) AS rank_year
FROM joined
GROUP BY
    d_year,
    sm_ship_mode_id,
    r_reason_desc,
    joined.date_sk,
    joined.demo_sk
ORDER BY total_return_amount DESC
LIMIT 100
