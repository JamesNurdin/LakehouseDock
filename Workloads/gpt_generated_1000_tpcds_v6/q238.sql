WITH returns_morning AS (
    SELECT
        td.t_hour,
        td.t_minute,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 6 AND 11
      AND wr.wr_web_page_sk IN (673, 1022)
      AND td.t_second < 10
    GROUP BY td.t_hour, td.t_minute
),
returns_evening AS (
    SELECT
        td.t_hour,
        td.t_minute,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 18 AND 23
      AND wr.wr_web_page_sk IN (2468, 2802)
      AND td.t_second >= 10
    GROUP BY td.t_hour, td.t_minute
)
SELECT *
FROM returns_morning
UNION ALL
SELECT *
FROM returns_evening
ORDER BY t_hour, t_minute
LIMIT 100
