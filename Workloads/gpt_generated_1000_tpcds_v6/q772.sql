WITH high_loss_hdemo AS (
    SELECT DISTINCT wr_returning_hdemo_sk AS hdemo_sk
    FROM web_returns
    WHERE wr_net_loss > 500
),

morning_returns AS (
    SELECT
        td.t_hour AS period,
        'hour' AS period_type,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt,
        SUM(wr.wr_return_amt_inc_tax) / (
            SELECT AVG(wr2.wr_return_amt_inc_tax) FROM web_returns wr2
        ) AS rel_to_overall_avg
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'AM'
      AND wr.wr_return_amt_inc_tax > 100
      AND NOT EXISTS (
          SELECT 1 FROM high_loss_hdemo h WHERE h.hdemo_sk = wr.wr_returning_hdemo_sk
      )
    GROUP BY td.t_hour
),

afternoon_returns AS (
    SELECT
        td.t_minute AS period,
        'minute' AS period_type,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt,
        SUM(wr.wr_return_amt_inc_tax) / (
            SELECT AVG(wr2.wr_return_amt_inc_tax) FROM web_returns wr2
        ) AS rel_to_overall_avg
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
      AND wr.wr_return_amt_inc_tax <= 100
      AND NOT EXISTS (
          SELECT 1 FROM high_loss_hdemo h WHERE h.hdemo_sk = wr.wr_returning_hdemo_sk
      )
    GROUP BY td.t_minute
)

SELECT DISTINCT
    period,
    period_type,
    return_cnt,
    total_return_amt,
    avg_return_amt,
    rel_to_overall_avg,
    RANK() OVER (PARTITION BY period_type ORDER BY total_return_amt DESC) AS amount_rank
FROM (
    SELECT * FROM morning_returns
    UNION ALL
    SELECT * FROM afternoon_returns
) combined
ORDER BY period_type, amount_rank
LIMIT 100
