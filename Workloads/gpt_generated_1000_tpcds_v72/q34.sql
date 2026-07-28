WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        wr.wr_refunded_cdemo_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_shift,
        t.t_second,
        r.r_reason_desc,
        cd.cd_gender,
        cd.cd_education_status
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND t.t_shift = 'second'
      AND t.t_second >= 5
      AND wr.wr_net_loss > 500
      AND wr.wr_return_ship_cost < 300
      AND r.r_reason_desc LIKE '%Warranty%'
      AND NOT EXISTS (
          SELECT 1
          FROM reason r_excl
          WHERE r_excl.r_reason_sk = r.r_reason_sk
            AND r_excl.r_reason_desc LIKE '%Lost%'
      )
)
SELECT DISTINCT
    d_date,
    d_year,
    r_reason_desc,
    cd_gender,
    cd_education_status,
    CASE
        WHEN wr_fee > 20 THEN 'High'
        ELSE 'Low'
    END AS fee_category,
    wr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY wr_net_loss DESC) AS loss_rank
FROM filtered_returns
ORDER BY loss_rank ASC, d_date DESC
LIMIT 100
