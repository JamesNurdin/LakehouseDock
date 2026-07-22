WITH filtered_sales AS (
    SELECT
        ss_sold_time_sk,
        ss_wholesale_cost,
        ss_quantity,
        ss_ticket_number,
        ss_ext_discount_amt,
        ss_net_profit,
        ss_sales_price
    FROM store_sales
    WHERE ss_wholesale_cost > 20.00
      AND ss_quantity >= 2
      AND ss_ticket_number IN (2, 7, 14)
      AND ss_ext_discount_amt < 5.00
)
SELECT
    td.t_meal_time,
    td.t_hour,
    SUM(fs.ss_net_profit) AS total_profit,
    AVG(fs.ss_sales_price) AS avg_sales_price,
    COUNT(*) AS sales_cnt
FROM filtered_sales fs
JOIN time_dim td
    ON fs.ss_sold_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND td.t_hour BETWEEN 10 AND 14
  AND EXISTS (
      SELECT 1
      FROM time_dim td2
      WHERE td2.t_time_sk = fs.ss_sold_time_sk
        AND td2.t_meal_time = 'dinner'
  )
GROUP BY td.t_meal_time, td.t_hour
ORDER BY total_profit DESC
