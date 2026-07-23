WITH base_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_returning_cdemo_sk,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        cd_ref.cd_credit_rating AS refunded_credit_rating,
        cd_ref.cd_dep_college_count AS refunded_dep_college_count,
        cd_ret.cd_credit_rating AS returning_credit_rating,
        cd_ret.cd_dep_employed_count AS returning_dep_employed_count,
        r.r_reason_desc,
        r.r_reason_id
    FROM web_returns AS wr
    JOIN date_dim AS d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics AS cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics AS cd_ret
        ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN reason AS r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND d.d_month_seq >= 1200 AND d.d_month_seq <= 1220
      AND cd_ref.cd_credit_rating IN ('Low Risk', 'Good')
      AND wr.wr_return_amt_inc_tax > 100.00
      AND r.r_reason_desc LIKE '%damage%'
),
agg_by_reason_year AS (
    SELECT
        r_reason_id,
        r_reason_desc,
        d_year,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        COUNT(*) AS return_cnt
    FROM base_returns
    GROUP BY r_reason_id, r_reason_desc, d_year
)
SELECT
    r_reason_id,
    r_reason_desc,
    d_year,
    total_net_loss,
    avg_return_amt_inc_tax,
    return_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank_by_year,
    SUM(total_net_loss) OVER (PARTITION BY r_reason_id ORDER BY d_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_3yr_net_loss,
    CASE
        WHEN total_net_loss > 1000 THEN 'High'
        WHEN total_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END AS net_loss_category
FROM agg_by_reason_year
ORDER BY d_year, loss_rank_by_year
LIMIT 100
