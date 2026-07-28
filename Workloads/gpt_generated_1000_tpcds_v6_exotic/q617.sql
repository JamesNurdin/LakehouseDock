WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sales_price,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_hdemo_sk
    FROM web_sales ws
)
,
filtered AS (
    SELECT
        s.*, 
        regexp_extract(hd.hd_buy_potential, '([A-Za-z]+) Potential', 1) AS extracted_potential
    FROM sales s
    JOIN household_demographics hd
      ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(hd.hd_buy_potential, '^[A-Za-z]+ Potential$')
)
SELECT
    d.d_year,
    extracted_potential,
    t.t_meal_time,
    substring(d.d_day_name, 1, 3) AS day_abbr,
    COUNT(DISTINCT f.ws_order_number) AS orders,
    SUM(f.ws_net_profit) AS total_profit,
    AVG(f.ws_sales_price) AS avg_sales_price
FROM filtered f
JOIN date_dim d
  ON f.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON f.ws_sold_time_sk = t.t_time_sk
WHERE
    t.t_meal_time LIKE 'Breakfast%'
    AND d.d_day_name LIKE 'S%'
GROUP BY
    d.d_year,
    extracted_potential,
    t.t_meal_time,
    substring(d.d_day_name, 1, 3)
ORDER BY total_profit DESC
LIMIT 10
