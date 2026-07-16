WITH hourly_shift_returns AS (
    SELECT
        td.t_hour AS hour_of_day,
        td.t_shift AS shift,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_tax,
        AVG(wr.wr_fee) AS avg_fee,
        SUM(wr.wr_return_quantity) AS total_quantity,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wr.wr_return_amt > 100.00
      AND td.t_am_pm = 'PM'
    GROUP BY td.t_hour, td.t_shift
)
SELECT
    hour_of_day,
    shift,
    num_returns,
    total_return_amount,
    total_tax,
    avg_fee,
    total_quantity,
    distinct_orders,
    RANK() OVER (ORDER BY total_return_amount DESC) AS rank_by_return_amount
FROM hourly_shift_returns
WHERE total_return_amount > 1000.00
ORDER BY total_return_amount DESC
LIMIT 50
