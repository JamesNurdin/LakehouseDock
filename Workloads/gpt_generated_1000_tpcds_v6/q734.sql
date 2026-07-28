WITH
    filtered_wr AS (
        SELECT
            wr_returned_time_sk,
            wr_returned_date_sk,
            wr_return_quantity,
            wr_return_amt,
            wr_return_tax,
            wr_return_ship_cost,
            wr_account_credit,
            wr_refunded_addr_sk
        FROM web_returns
        WHERE wr_return_ship_cost > 100
          AND wr_return_ship_cost < 3500
          AND wr_account_credit < 500
          AND wr_account_credit >= 0
          AND wr_refunded_addr_sk IN (1430611, 3297235)
    ),
    agg_wr AS (
        SELECT
            wr_returned_time_sk,
            SUM(wr_return_amt) AS total_return_amt,
            AVG(wr_return_tax) AS avg_return_tax,
            COUNT(*) AS return_cnt,
            MIN(wr_return_ship_cost) AS min_ship_cost,
            MAX(wr_account_credit) AS max_account_credit
        FROM filtered_wr
        GROUP BY wr_returned_time_sk
    ),
    shift_set AS (
        SELECT t_shift FROM time_dim WHERE t_shift = 'first'
        UNION
        SELECT t_shift FROM time_dim WHERE t_shift = 'second'
    )
SELECT
    td.t_shift,
    td.t_time,
    agg.total_return_amt,
    agg.avg_return_tax,
    agg.return_cnt,
    agg.min_ship_cost,
    agg.max_account_credit,
    ROW_NUMBER() OVER (PARTITION BY td.t_shift ORDER BY agg.total_return_amt DESC) AS rn,
    (SELECT AVG(wr_return_amt) FROM web_returns) AS overall_avg_return_amt
FROM agg_wr agg
JOIN time_dim td
    ON agg.wr_returned_time_sk = td.t_time_sk
WHERE td.t_shift IN (SELECT t_shift FROM shift_set)
  AND td.t_time BETWEEN 5 AND 18
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr_ex
        WHERE wr_ex.wr_returned_time_sk = agg.wr_returned_time_sk
          AND wr_ex.wr_return_ship_cost > 2000
    )
ORDER BY agg.total_return_amt DESC
LIMIT 100
