WITH filtered_sales AS (
    SELECT
        ws_sold_time_sk,
        ws_order_number,
        ws_quantity,
        ws_wholesale_cost,
        ws_ext_discount_amt,
        ws_net_paid,
        ws_net_profit,
        ws_ship_customer_sk
    FROM web_sales
    WHERE ws_wholesale_cost >= 50
      AND ws_ship_customer_sk IN (2604541, 11888307)
      AND ws_quantity > 1
      AND ws_ext_discount_amt > 0
)
SELECT
    td.t_meal_time,
    td.t_am_pm,
    td.t_hour,
    COUNT(DISTINCT fs.ws_order_number) AS order_cnt,
    SUM(fs.ws_net_paid) AS total_net_paid,
    AVG(fs.ws_ext_discount_amt) AS avg_discount_amt,
    MIN(fs.ws_net_profit) AS min_net_profit,
    MAX(fs.ws_net_profit) AS max_net_profit,
    SUM(CASE WHEN fs.ws_net_profit > 500 THEN 1 ELSE 0 END) AS high_profit_txn_cnt,
    SUM(CASE WHEN fs.ws_net_profit <= 500 THEN 1 ELSE 0 END) AS low_profit_txn_cnt
FROM filtered_sales AS fs
JOIN time_dim AS td
    ON fs.ws_sold_time_sk = td.t_time_sk
WHERE td.t_meal_time = 'lunch'
  AND td.t_am_pm = 'PM'
GROUP BY td.t_meal_time, td.t_am_pm, td.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
