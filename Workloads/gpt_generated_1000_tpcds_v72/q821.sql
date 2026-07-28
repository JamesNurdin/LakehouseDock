WITH sales_agg AS (
  SELECT
    s.s_store_id AS entity_id,
    d.d_year AS year,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    AVG(ss.ss_sales_price) AS avg_price
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE i.i_wholesale_cost > 5.00
    AND d.d_year = 2001
    AND t.t_meal_time = 'lunch'
    AND ib.ib_lower_bound >= 60000
    AND EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND r.r_reason_desc = 'Damaged'
    )
  GROUP BY s.s_store_id, d.d_year
),
web_agg AS (
  SELECT
    CAST(ws.ws_web_site_sk AS varchar) AS entity_id,
    d.d_year AS year,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    AVG(ws.ws_sales_price) AS avg_price
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE i.i_wholesale_cost > 5.00
    AND d.d_year = 2001
    AND t.t_meal_time = 'lunch'
    AND ib.ib_lower_bound >= 60000
  GROUP BY ws.ws_web_site_sk, d.d_year
)
SELECT
  combined.entity_id,
  combined.year,
  combined.total_profit,
  combined.orders,
  combined.avg_price
FROM (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM web_agg
) AS combined
ORDER BY combined.total_profit DESC
LIMIT 100
