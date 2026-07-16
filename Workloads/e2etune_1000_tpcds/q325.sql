WITH hourly_sales AS (
    SELECT
        td.t_hour,
        td.t_shift,
        td.t_meal_time,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_coupon_amt > 1000.00
    GROUP BY td.t_hour, td.t_shift, td.t_meal_time
    HAVING SUM(ss.ss_ext_sales_price) > 5000.00
)
SELECT
    t_hour,
    t_shift,
    t_meal_time,
    total_sales,
    total_profit,
    avg_discount,
    sales_count,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM hourly_sales
ORDER BY profit_rank
LIMIT 10
