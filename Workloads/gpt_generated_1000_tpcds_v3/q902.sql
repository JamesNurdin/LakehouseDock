WITH sales_agg AS (
  SELECT
    hd.hd_buy_potential,
    t.t_meal_time,
    t.t_time_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid
  FROM store_sales ss
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                     AND ws.ws_sold_time_sk = t.t_time_sk
  WHERE
    hd.hd_buy_potential LIKE '5%'
    AND REGEXP_LIKE(t.t_time_id, '^AAAAAAA[AB]')
    AND t.t_meal_time IN ('breakfast', 'lunch')
  GROUP BY
    hd.hd_buy_potential,
    t.t_meal_time,
    t.t_time_id
)
SELECT
  hd_buy_potential,
  t_meal_time,
  distinct_store_tickets,
  distinct_web_orders,
  total_store_net_paid,
  total_web_net_paid,
  CONCAT('Meal ', t_meal_time, ' - ', hd_buy_potential) AS segment_desc,
  REGEXP_EXTRACT(t_time_id, '(A{5,})', 1) AS time_pattern,
  SUBSTRING(t_time_id, 1, 8) AS time_prefix
FROM sales_agg
ORDER BY total_store_net_paid DESC
LIMIT 100
