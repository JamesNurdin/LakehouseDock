WITH dept_monthly AS (
    SELECT
        cp.cp_department,
        d.d_year,
        d.d_moy AS month,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        COUNT(DISTINCT cd.cd_demo_sk) AS distinct_refunded_customers
    FROM
        web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN catalog_page cp ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        cp.cp_type = 'monthly'
        AND d.d_year BETWEEN 1998 AND 2002
        AND cd.cd_education_status IN ('College', 'Graduate')
    GROUP BY
        cp.cp_department,
        d.d_year,
        d.d_moy
    HAVING
        SUM(wr.wr_net_loss) > 0
)
SELECT
    dm.cp_department,
    dm.d_year,
    dm.month,
    dm.total_return_amt,
    dm.total_net_loss,
    dm.avg_return_qty,
    dm.distinct_orders,
    dm.distinct_refunded_customers,
    RANK() OVER (PARTITION BY dm.d_year ORDER BY dm.total_net_loss DESC) AS dept_net_loss_rank
FROM
    dept_monthly dm
ORDER BY
    dm.d_year,
    dm.month,
    dept_net_loss_rank
