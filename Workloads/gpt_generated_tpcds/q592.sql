WITH hourly_metrics AS (
    SELECT
        time_dim.t_hour,
        time_dim.t_meal_time,
        SUM(store_sales.ss_ext_sales_price) AS sales_amount,
        SUM(store_sales.ss_net_profit) AS profit_amount,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS ticket_cnt,
        AVG(store_sales.ss_net_paid) AS avg_net_paid,
        AVG(store_sales.ss_ext_discount_amt) AS avg_discount_amt
    FROM store_sales
    JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
    WHERE time_dim.t_hour BETWEEN 9 AND 17
    GROUP BY time_dim.t_hour, time_dim.t_meal_time
)
SELECT
    t_hour,
    t_meal_time,
    sales_amount,
    profit_amount,
    ticket_cnt,
    avg_net_paid,
    avg_discount_amt,
    sales_amount / SUM(sales_amount) OVER () AS sales_pct_of_day,
    profit_amount / SUM(profit_amount) OVER () AS profit_pct_of_day,
    profit_amount / NULLIF(sales_amount, 0) AS profit_margin,
    ROW_NUMBER() OVER (ORDER BY sales_amount DESC) AS sales_rank
FROM hourly_metrics
ORDER BY t_hour, t_meal_time
