WITH high_income_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 80000
)
SELECT
    'catalog' AS channel,
    td.t_meal_time,
    SUM(cs.cs_net_profit) AS total_profit,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk IN (SELECT c_customer_sk FROM high_income_customers)
    ) AS avg_profit_all_customers
FROM catalog_sales cs
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
WHERE cs.cs_bill_customer_sk IN (SELECT c_customer_sk FROM high_income_customers)
  AND td.t_am_pm = 'PM'
GROUP BY td.t_meal_time

UNION ALL

SELECT
    'web' AS channel,
    td.t_meal_time,
    SUM(ws.ws_net_profit) AS total_profit,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk IN (SELECT c_customer_sk FROM high_income_customers)
    ) AS avg_profit_all_customers
FROM web_sales ws
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
WHERE ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM high_income_customers)
  AND td.t_am_pm = 'PM'
GROUP BY td.t_meal_time

ORDER BY channel, total_profit DESC
LIMIT 100
