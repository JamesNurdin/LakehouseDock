WITH morning AS (
    SELECT
        td.t_shift AS shift,
        SUM(wr.wr_return_amt) AS total_return
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
      AND td.t_sub_shift = 'morning'
    GROUP BY td.t_shift
),
afternoon AS (
    SELECT
        td.t_shift AS shift,
        SUM(wr.wr_return_amt) AS total_return
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'second'
      AND td.t_sub_shift = 'afternoon'
    GROUP BY td.t_shift
),
night AS (
    SELECT
        td.t_shift AS shift,
        SUM(wr.wr_return_amt) AS total_return
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_sub_shift = 'night'
    GROUP BY td.t_shift
),
combined AS (
    SELECT shift, total_return FROM morning
    UNION
    SELECT shift, total_return FROM afternoon
)
SELECT shift, total_return
FROM combined
EXCEPT
SELECT shift, total_return FROM night
ORDER BY shift, total_return DESC
LIMIT 100
