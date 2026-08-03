WITH max_return AS (
    SELECT MAX(wr_return_amt_inc_tax) AS max_amt
    FROM web_returns
)

SELECT
    sub.r_reason_desc AS reason_desc,
    sub.t_hour AS hour_of_day,
    SUM(sub.wr_return_amt_inc_tax) AS total_return_amount,
    CASE
        WHEN SUM(sub.wr_return_amt_inc_tax) > (SELECT max_amt FROM max_return) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_level,
    COUNT(*) AS return_count
FROM (
    SELECT
        wr.wr_return_amt_inc_tax,
        r.r_reason_desc,
        t.t_hour
    FROM web_returns AS wr
    JOIN reason AS r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim AS t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics AS hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count > 1
      AND r.r_reason_id = 'AAAAAAAALAAAAAAA'
    UNION ALL
    SELECT
        wr.wr_return_amt_inc_tax,
        r.r_reason_desc,
        t.t_hour
    FROM web_returns AS wr
    JOIN reason AS r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim AS t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics AS hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count > 1
      AND r.r_reason_desc LIKE '%color%'
) AS sub
GROUP BY sub.r_reason_desc, sub.t_hour
ORDER BY total_return_amount DESC
LIMIT 10
