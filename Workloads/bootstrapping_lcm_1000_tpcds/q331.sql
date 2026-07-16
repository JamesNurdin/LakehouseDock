WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        cd_ref.cd_gender,
        cd_ret.cd_marital_status,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        MAX(cr.cr_return_tax) AS max_return_tax,
        MIN(cr.cr_store_credit) AS min_store_credit,
        COUNT(DISTINCT s.s_store_id) AS distinct_stores
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND t.t_am_pm = 'PM'
      AND cd_ref.cd_gender = 'F'
    GROUP BY d.d_year, d.d_month_seq, t.t_hour, cd_ref.cd_gender, cd_ret.cd_marital_status
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.t_hour,
    a.cd_gender,
    a.cd_marital_status,
    a.total_net_loss,
    a.avg_fee,
    a.distinct_orders,
    a.total_return_amount,
    a.return_count,
    a.avg_return_qty,
    a.max_return_tax,
    a.min_store_credit,
    a.distinct_stores,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS rank_within_year
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
