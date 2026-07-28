WITH filtered AS (
    SELECT
        cr.cr_returning_addr_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_order_number,
        cd.cd_education_status,
        cd.cd_dep_employed_count,
        td.t_sub_shift,
        td.t_hour,
        wr.wr_return_amt,
        wr.wr_fee
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_returning_addr_sk IN (1012485, 5082377)
      AND cr.cr_return_amount > 100
      AND cr.cr_fee BETWEEN 5 AND 50
      AND cd.cd_education_status = '4 yr Degree'
      AND cd.cd_dep_employed_count >= 2
      AND td.t_sub_shift = 'afternoon'
      AND wr.wr_return_amt < 200
),
agg AS (
    SELECT
        cd_education_status AS education_status,
        t_sub_shift AS sub_shift,
        t_hour AS hour,
        SUM(cr_return_amount) AS sum_cr_return_amount,
        SUM(wr_return_amt) AS sum_wr_return_amt,
        AVG(cr_return_quantity) AS avg_cr_return_quantity,
        COUNT(DISTINCT cr_order_number) AS distinct_cr_orders,
        MAX(cr_fee) AS max_cr_fee,
        MIN(wr_fee) AS min_wr_fee
    FROM filtered
    GROUP BY cd_education_status, t_sub_shift, t_hour
)
SELECT
    education_status,
    sub_shift,
    hour,
    sum_cr_return_amount,
    sum_wr_return_amt,
    avg_cr_return_quantity,
    distinct_cr_orders,
    max_cr_fee,
    min_wr_fee,
    SUM(sum_cr_return_amount) OVER (PARTITION BY education_status ORDER BY hour ROWS UNBOUNDED PRECEDING) AS cumulative_return_amount_by_edu_hour,
    RANK() OVER (PARTITION BY education_status ORDER BY sum_cr_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY sum_cr_return_amount DESC
LIMIT 20
