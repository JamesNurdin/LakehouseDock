WITH returns_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        date_dim.d_year,
        date_dim.d_month_seq,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        MAX(cc.cc_employees) AS call_center_employees
    FROM catalog_returns cr
    JOIN date_dim ON cr.cr_returned_date_sk = date_dim.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_tax_percentage > 5.00
      AND date_dim.d_year = 2020
      AND w.w_state = 'CA'
      AND r.r_reason_desc LIKE '%damage%'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        date_dim.d_year,
        date_dim.d_month_seq,
        r.r_reason_desc
)
SELECT
    cc_call_center_id,
    cc_name,
    d_year,
    d_month_seq,
    r_reason_desc,
    total_net_loss,
    total_return_amount,
    avg_return_quantity,
    distinct_customers,
    total_refunded_cash,
    call_center_employees,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_loss DESC) AS net_loss_rank
FROM returns_agg
ORDER BY d_year, d_month_seq, net_loss_rank
LIMIT 100
