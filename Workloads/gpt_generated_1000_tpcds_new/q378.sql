WITH agg_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM store_returns sr
    WHERE sr.sr_return_time_sk BETWEEN 40000 AND 50000
      AND sr.sr_refunded_cash > 20.00
      AND sr.sr_return_quantity >= 1
      AND sr.sr_return_ship_cost < 50.00
    GROUP BY sr.sr_returned_date_sk, sr.sr_reason_sk
), filtered_dates AS (
    SELECT sr.sr_returned_date_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_week_seq = 18
    EXCEPT
    SELECT sr.sr_returned_date_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Package was damaged'
)
SELECT
    d.d_year,
    d.d_quarter_name,
    r.r_reason_desc,
    a.total_return_amt,
    a.cnt_returns,
    a.avg_return_amt,
    CASE WHEN d.d_current_quarter = 'Y' THEN a.total_return_amt ELSE 0 END AS current_quarter_total,
    (
        SELECT SUM(sr_inner.sr_return_amt)
        FROM store_returns sr_inner
        WHERE sr_inner.sr_reason_sk = a.sr_reason_sk
    ) AS total_return_for_reason_all_dates
FROM agg_returns a
JOIN date_dim d ON a.sr_returned_date_sk = d.d_date_sk
JOIN reason r ON a.sr_reason_sk = r.r_reason_sk
WHERE a.sr_returned_date_sk IN (SELECT fd.sr_returned_date_sk FROM filtered_dates fd)
  AND d.d_current_week = 'N'
  AND d.d_holiday = 'N'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr_check
        WHERE sr_check.sr_returned_date_sk = a.sr_returned_date_sk
          AND sr_check.sr_return_quantity > 5
    )
GROUP BY
    d.d_year,
    d.d_quarter_name,
    r.r_reason_desc,
    a.total_return_amt,
    a.cnt_returns,
    a.avg_return_amt,
    d.d_current_quarter,
    a.sr_reason_sk
ORDER BY d.d_year DESC, total_return_for_reason_all_dates DESC
LIMIT 100
