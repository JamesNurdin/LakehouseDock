WITH demo_filtered AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_education_status,
        cd_dep_count,
        cd_dep_employed_count
    FROM customer_demographics
    WHERE cd_gender = 'F'
      AND cd_education_status = 'Primary'
      AND cd_dep_employed_count >= 1
)
SELECT
    wr.wr_order_number,
    wr.wr_return_amt,
    wr.wr_net_loss,
    td.t_hour,
    td.t_minute,
    ref_demo.cd_gender,
    ref_demo.cd_education_status,
    CASE
        WHEN wr.wr_net_loss > (
            SELECT avg(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_returned_time_sk = wr.wr_returned_time_sk
        ) THEN 'Above Avg Return Amt'
        ELSE 'Below Avg Return Amt'
    END AS loss_vs_avg_return,
    RANK() OVER (PARTITION BY ref_demo.cd_gender ORDER BY wr.wr_net_loss DESC) AS net_loss_rank,
    ROW_NUMBER() OVER (PARTITION BY td.t_hour ORDER BY wr.wr_return_quantity DESC) AS rn_quantity
FROM web_returns wr
JOIN time_dim td
    ON wr.wr_returned_time_sk = td.t_time_sk
JOIN demo_filtered ref_demo
    ON wr.wr_refunded_cdemo_sk = ref_demo.cd_demo_sk
JOIN demo_filtered ret_demo
    ON wr.wr_returning_cdemo_sk = ret_demo.cd_demo_sk
WHERE ref_demo.cd_gender = 'F'
  AND ref_demo.cd_education_status = 'Primary'
  AND td.t_hour BETWEEN 4 AND 12
  AND td.t_second <= 12
  AND wr.wr_return_amt > 100
ORDER BY net_loss_rank ASC, wr.wr_net_loss DESC
LIMIT 100
