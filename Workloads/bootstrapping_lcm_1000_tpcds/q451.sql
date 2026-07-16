WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        sm.sm_type,
        sm.sm_carrier,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        d_ret.d_year,
        d_ret.d_month_seq,
        COUNT(*) AS total_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_ret.d_year BETWEEN 2015 AND 2020
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        sm.sm_type,
        sm.sm_carrier,
        cd_ref.cd_gender,
        cd_ret.cd_gender,
        d_ret.d_year,
        d_ret.d_month_seq
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_city,
    a.sm_type,
    a.sm_carrier,
    a.refunded_gender,
    a.returning_gender,
    a.d_year,
    a.d_month_seq,
    a.total_returns,
    a.total_net_loss,
    a.total_return_amount,
    a.avg_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_net_loss DESC) AS loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
