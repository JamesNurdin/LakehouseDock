WITH filtered_returns AS (
    SELECT
        d.d_day_name,
        t.t_meal_time,
        wr.wr_return_amt,
        i.inv_quantity_on_hand,
        wr.wr_order_number,
        t.t_time_id
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_day_name LIKE 'Mon%'
      AND regexp_like(t.t_time_id, '^A{7}[A-Z]')
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_date_sk = d.d_date_sk
            AND i2.inv_quantity_on_hand > 800
      )
)
SELECT
    COALESCE(d_day_name, 'All Days') AS day_name,
    COALESCE(t_meal_time, 'All Meals') AS meal_time,
    concat(COALESCE(d_day_name, ''), ' - ', COALESCE(t_meal_time, '')) AS day_meal,
    sum(wr_return_amt) AS total_return_amount,
    sum(inv_quantity_on_hand) AS total_inventory_quantity,
    count(DISTINCT wr_order_number) AS distinct_orders,
    max(regexp_extract(t_time_id, '(A{7})([A-Z])', 2)) AS time_code_letter,
    CASE 
        WHEN sum(wr_return_amt) > (SELECT avg(wr_return_amt) FROM web_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_vs_average,
    CASE 
        WHEN sum(wr_return_amt) >= 1500 THEN 'High'
        WHEN sum(wr_return_amt) >= 750 THEN 'Medium'
        ELSE 'Low'
    END AS return_level
FROM filtered_returns
GROUP BY ROLLUP (d_day_name, t_meal_time)
ORDER BY day_name ASC NULLS LAST, meal_time ASC NULLS LAST
LIMIT 100
