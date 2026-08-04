WITH agg_ws AS (
    SELECT
        ws_sold_time_sk,
        ws_ship_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_paid,
        AVG(ws_wholesale_cost) AS avg_wholesale,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_wholesale_cost > 10
    GROUP BY ws_sold_time_sk, ws_ship_customer_sk
)
SELECT
    td.t_shift,
    a.ws_ship_customer_sk,
    SUM(a.total_paid) AS shift_total_paid,
    SUM(a.sales_cnt) AS shift_sales_cnt,
    AVG(a.avg_wholesale) AS shift_avg_wholesale,
    RANK() OVER (ORDER BY SUM(a.total_paid) DESC) AS revenue_rank
FROM agg_ws a
JOIN time_dim td
    ON a.ws_sold_time_sk = td.t_time_sk
WHERE
    td.t_am_pm = 'PM'
    AND td.t_hour BETWEEN 12 AND 18
    AND td.t_minute IN (0, 15, 30, 45)
    AND td.t_second > 10
    AND a.avg_wholesale < 50
    AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_ship_customer_sk = a.ws_ship_customer_sk
          AND ws2.ws_net_paid_inc_tax > 10000
    )
GROUP BY td.t_shift, a.ws_ship_customer_sk
HAVING SUM(a.total_paid) > 5000
ORDER BY revenue_rank, td.t_shift
OFFSET 0 LIMIT 100
