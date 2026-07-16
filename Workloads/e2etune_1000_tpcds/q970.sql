WITH returns_by_time AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_return_amt,
        wr.wr_fee,
        wr.wr_return_quantity,
        t.t_hour,
        t.t_shift,
        t.t_meal_time
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_shift = 'Morning'
      AND t.t_meal_time IN ('Breakfast', 'Lunch')
)
SELECT
    rbt.t_hour,
    rbt.t_shift,
    rbt.t_meal_time,
    SUM(rbt.wr_return_amt) AS total_return_amount,
    SUM(rbt.wr_fee) AS total_fee,
    COUNT(*) AS return_transactions,
    AVG(rbt.wr_return_quantity) AS avg_quantity,
    (SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_type = 'monthly') AS monthly_page_count,
    RANK() OVER (ORDER BY SUM(rbt.wr_return_amt) DESC) AS revenue_rank
FROM returns_by_time rbt
GROUP BY rbt.t_hour, rbt.t_shift, rbt.t_meal_time
HAVING SUM(rbt.wr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 20
