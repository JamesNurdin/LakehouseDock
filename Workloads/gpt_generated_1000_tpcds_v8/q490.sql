WITH
    agg_returns AS (
        SELECT
            sr_returned_date_sk,
            SUM(sr_return_amt_inc_tax)          AS total_return_amt_inc_tax,
            SUM(sr_refunded_cash)               AS total_refunded_cash,
            AVG(sr_return_quantity)            AS avg_return_qty,
            SUM(sr_net_loss)                    AS total_net_loss,
            COUNT(*)                            AS cnt_returns
        FROM store_returns
        WHERE sr_return_amt_inc_tax > 20
          AND sr_refunded_cash < 200
          AND sr_return_ship_cost BETWEEN 10 AND 500
          AND sr_return_quantity > 0
          AND sr_fee IS NOT NULL
        GROUP BY sr_returned_date_sk
    ),
    date_filtered AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2001
          AND d_month_seq BETWEEN 1200 AND 1300
          AND d_weekend = 'N'
          AND d_holiday = 'N'
          AND d_current_day = 'N'
    ),
    intersect_dates AS (
        SELECT sr_returned_date_sk
        FROM store_returns
        WHERE sr_return_amt_inc_tax > 1000
        INTERSECT
        SELECT sr_returned_date_sk
        FROM store_returns
        WHERE sr_refunded_cash > 150
    )
SELECT
    d.d_date_id,
    d.d_year,
    ar.sr_returned_date_sk,
    ar.total_return_amt_inc_tax,
    ar.total_refunded_cash,
    CASE
        WHEN ar.total_return_amt_inc_tax >= 5000 THEN 'High'
        WHEN ar.total_return_amt_inc_tax >= 2000 THEN 'Medium'
        ELSE 'Low'
    END AS return_bucket,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ar.total_return_amt_inc_tax DESC) AS yearly_rank,
    lt.parity,
    ar.cnt_returns
FROM date_filtered d
FULL OUTER JOIN agg_returns ar
    ON d.d_date_sk = ar.sr_returned_date_sk
LEFT JOIN LATERAL (
    SELECT CASE WHEN ar.sr_returned_date_sk % 2 = 0 THEN 'Even' ELSE 'Odd' END AS parity
) lt ON TRUE
WHERE (
        d.d_year = 2001 OR d.d_year IS NULL
    )
  AND (
        ar.total_return_amt_inc_tax > 0 OR ar.total_return_amt_inc_tax IS NULL
    )
  AND (
        ar.total_refunded_cash < 500 OR ar.total_refunded_cash IS NULL
    )
  AND (
        d.d_month_seq BETWEEN 1200 AND 1300 OR d.d_month_seq IS NULL
    )
  AND (
        d.d_weekend = 'N' OR d.d_weekend IS NULL
    )
  AND EXISTS (SELECT 1 FROM intersect_dates i WHERE i.sr_returned_date_sk = ar.sr_returned_date_sk)
ORDER BY yearly_rank, ar.total_return_amt_inc_tax DESC
OFFSET 10 LIMIT 100
