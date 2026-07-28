WITH base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        td.t_time,
        td.t_hour,
        td.t_minute,
        cd_ret.cd_education_status,
        cd_ret.cd_gender,
        cd_ret.cd_dep_count
    FROM tpcds.web_returns AS wr
    JOIN tpcds.time_dim AS td
      ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN tpcds.customer_demographics AS cd_ret
      ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN tpcds.customer_demographics AS cd_ref
      ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17                         -- predicate 1
      AND td.t_minute IN (0, 15, 30, 45)                     -- predicate 2
      AND cd_ret.cd_gender = 'M'                           -- predicate 3
      AND cd_ret.cd_education_status IN ('College', 'Advanced Degree') -- predicate 4
      AND wr.wr_return_quantity > 0                       -- predicate 5
),
agg AS (
    SELECT
        t_time,
        t_hour,
        t_minute,
        cd_education_status,
        cd_gender,
        SUM(wr_return_quantity)   AS total_qty,
        SUM(wr_return_amt)        AS total_return_amt,
        SUM(wr_net_loss)          AS total_net_loss
    FROM base
    GROUP BY
        t_time,
        t_hour,
        t_minute,
        cd_education_status,
        cd_gender
)
SELECT
    t_time,
    t_hour,
    t_minute,
    cd_education_status,
    cd_gender,
    total_qty,
    total_return_amt,
    total_net_loss,
    RANK() OVER (PARTITION BY cd_education_status ORDER BY total_net_loss DESC) AS loss_rank_by_edu,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC)                     AS overall_rank,
    CASE
        WHEN total_net_loss > 10000 THEN 'HIGH'
        WHEN total_net_loss > 5000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
