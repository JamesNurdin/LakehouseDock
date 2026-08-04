WITH refunded AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_quantity,
        wr.wr_account_credit,
        wr.wr_returned_date_sk
    FROM web_returns AS wr
    JOIN household_demographics AS hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451158 AND 2452109               -- filter 1 (date range)
      AND hd.hd_vehicle_count >= 1                                         -- filter 2
      AND hd.hd_dep_count <= 5                                             -- filter 3
      AND wr.wr_account_credit > 20.00                                     -- filter 4
),
returning AS (
    SELECT
        hd.hd_demo_sk
    FROM web_returns AS wr
    JOIN household_demographics AS hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count = 0                                          -- filter 5
      AND wr.wr_return_amt > 30.00                                          -- filter 6
),
agg AS (
    SELECT
        hd_demo_sk,
        hd_vehicle_count,
        SUM(wr_return_amt)   AS total_return_amt,
        AVG(wr_return_tax)   AS avg_return_tax,
        COUNT(*)             AS cnt,
        MIN(wr_return_quantity) AS min_qty,
        MAX(wr_return_quantity) AS max_qty
    FROM refunded
    GROUP BY GROUPING SETS (
        (hd_demo_sk, hd_vehicle_count),
        (hd_demo_sk),
        ()
    )
)
SELECT *
FROM agg
WHERE hd_demo_sk IN (
    SELECT hd_demo_sk FROM refunded
    EXCEPT
    SELECT hd_demo_sk FROM returning
)
LIMIT 100
