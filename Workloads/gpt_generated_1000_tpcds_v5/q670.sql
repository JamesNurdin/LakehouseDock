WITH daily_agg AS (
    SELECT
        d.d_year,
        t.t_meal_time,
        i.inv_warehouse_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1905 AND 1915
      AND t.t_meal_time IN ('breakfast', 'lunch')
      AND i.inv_warehouse_sk IN (9, 10, 12, 15, 16)
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY d.d_year, t.t_meal_time, i.inv_warehouse_sk
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    d_year,
    t_meal_time,
    inv_warehouse_sk,
    total_return_amt,
    total_quantity_on_hand,
    return_transactions,
    avg_return_quantity,
    SUM(total_return_amt) OVER (PARTITION BY t_meal_time ORDER BY d_year) AS running_total_return_by_meal,
    RANK() OVER (PARTITION BY t_meal_time ORDER BY total_return_amt DESC) AS return_amt_rank
FROM daily_agg
ORDER BY d_year DESC, total_return_amt DESC
LIMIT 100
