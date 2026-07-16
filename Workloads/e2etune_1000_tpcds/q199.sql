WITH sales_agg AS (
    SELECT
        ss_sold_time_sk AS sold_time_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM store_sales
    WHERE ss_ext_discount_amt > 5.00
      AND ss_net_paid > 0
    GROUP BY ss_sold_time_sk
)
SELECT
    t.t_shift,
    t.t_hour,
    t.t_meal_time,
    s.total_net_profit,
    s.total_quantity,
    s.avg_discount,
    s.distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY t.t_shift ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
JOIN time_dim t
  ON s.sold_time_sk = t.t_time_sk
WHERE t.t_shift IS NOT NULL
ORDER BY t.t_shift, profit_rank
LIMIT 100
