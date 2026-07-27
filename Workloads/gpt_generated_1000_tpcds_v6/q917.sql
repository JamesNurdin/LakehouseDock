WITH high_spenders AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS orders,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE ib.ib_lower_bound >= 50000               -- focus on higher‑income households
      AND t.t_hour BETWEEN 9 AND 18                -- sales made during business hours
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    total_profit,
    orders,
    channel
FROM high_spenders
UNION ALL
SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS orders,
    'web' AS channel
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE ib.ib_upper_bound <= 75000               -- focus on lower‑to‑mid income households
  AND t.t_hour NOT BETWEEN 0 AND 6               -- exclude very early night sales
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
HAVING SUM(ws.ws_net_profit) > 500
ORDER BY total_profit DESC
LIMIT 100
