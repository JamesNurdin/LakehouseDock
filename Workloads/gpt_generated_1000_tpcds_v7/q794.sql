WITH filtered_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_time_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 1000.00
      AND ss.ss_ext_tax BETWEEN 10 AND 200
      AND ss.ss_quantity >= 2
)
SELECT
    i.i_brand,
    i.i_category,
    t.t_meal_time,
    t.t_hour,
    COUNT(DISTINCT f.ss_ticket_number) AS num_tickets,
    SUM(f.ss_ext_sales_price) AS total_sales,
    AVG(f.ss_ext_tax) AS avg_tax,
    MIN(f.ss_ext_sales_price) AS min_sale,
    MAX(f.ss_ext_sales_price) AS max_sale
FROM filtered_sales f
JOIN item i ON f.ss_item_sk = i.i_item_sk
JOIN time_dim t ON f.ss_sold_time_sk = t.t_time_sk
WHERE i.i_rec_start_date >= DATE '1999-01-01'
  AND i.i_rec_end_date <= DATE '2002-12-31'
  AND i.i_wholesale_cost < 20.00
  AND i.i_manufact LIKE '%stable%'
  AND t.t_am_pm = 'PM'
  AND t.t_meal_time = 'dinner'
GROUP BY
    i.i_brand,
    i.i_category,
    t.t_meal_time,
    t.t_hour
ORDER BY total_sales DESC
LIMIT 20
