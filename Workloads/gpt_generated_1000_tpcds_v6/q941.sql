WITH daily_income AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_quantity
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND d.d_month_seq BETWEEN 1 AND 12
      AND ib.ib_upper_bound >= 50000
      AND hd.hd_dep_count <= 4
    GROUP BY d.d_year, d.d_month_seq, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    di.d_year,
    di.d_month_seq,
    di.ib_lower_bound,
    di.ib_upper_bound,
    di.total_return_amt,
    di.return_cnt,
    di.total_return_amt / di.return_cnt AS avg_return_per_transaction,
    (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2) AS overall_avg_return_amt
FROM daily_income di
WHERE di.total_return_amt > 10000
  AND di.return_cnt >= 5
  AND di.avg_quantity > 1
  AND EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = di.ib_income_band_sk
          AND ib2.ib_lower_bound < 150000
      )
ORDER BY di.d_year DESC, di.d_month_seq ASC, di.total_return_amt DESC
LIMIT 100
