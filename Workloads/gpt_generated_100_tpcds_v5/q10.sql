WITH am_returns AS (
    SELECT
        td.t_hour,
        td.t_am_pm,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns AS wr
    JOIN time_dim AS td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'AM'
      AND wr.wr_return_amt > 100
    GROUP BY td.t_hour, td.t_am_pm
),
pm_returns AS (
    SELECT
        td.t_hour,
        td.t_am_pm,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns AS wr
    JOIN time_dim AS td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
      AND wr.wr_return_amt > 100
    GROUP BY td.t_hour, td.t_am_pm
)
SELECT DISTINCT
    hour,
    period,
    total_return_amt,
    total_refunded_cash,
    distinct_orders
FROM (
    SELECT
        am.t_hour AS hour,
        am.t_am_pm AS period,
        am.total_return_amt,
        am.total_refunded_cash,
        am.distinct_orders
    FROM am_returns AS am
    UNION ALL
    SELECT
        pm.t_hour AS hour,
        pm.t_am_pm AS period,
        pm.total_return_amt,
        pm.total_refunded_cash,
        pm.distinct_orders
    FROM pm_returns AS pm
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
