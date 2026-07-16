WITH agg AS (
    SELECT
        t.t_hour,
        t.t_shift,
        t.t_meal_time,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        SUM(CASE WHEN wr.wr_return_amt > 100 THEN wr.wr_return_amt ELSE 0 END) AS high_value_returns,
        approx_percentile(wr.wr_return_amt, 0.5) AS median_return_amt
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 18
      AND wr.wr_web_page_sk IN (
          SELECT cp_catalog_page_sk
          FROM catalog_page
          WHERE cp_type = 'monthly'
      )
    GROUP BY t.t_hour, t.t_shift, t.t_meal_time
    HAVING COUNT(*) > 5
)
SELECT
    a.t_hour,
    a.t_shift,
    a.t_meal_time,
    a.total_returns,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_qty,
    a.high_value_returns,
    a.median_return_amt,
    ROW_NUMBER() OVER (PARTITION BY a.t_shift ORDER BY a.total_return_amount DESC) AS rn_by_shift
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 20
