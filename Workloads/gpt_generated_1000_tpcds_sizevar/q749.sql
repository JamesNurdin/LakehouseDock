WITH sales_sample AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_wholesale_cost,
    ws.ws_list_price,
    ws.ws_net_paid,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ARRAY[ws.ws_quantity, ws.ws_wholesale_cost, ws.ws_list_price] AS metrics
  FROM tpcds.web_sales AS ws TABLESAMPLE BERNOULLI (5)
  WHERE ws.ws_net_paid > 500
    AND ws.ws_quantity BETWEEN 1 AND 10
    AND ws.ws_wholesale_cost < 50
    AND ws.ws_list_price > 100
    AND ws.ws_ext_sales_price > 200
    AND ws.ws_net_profit > 0
),
joined_data AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    d.d_holiday,
    d.d_current_week,
    t.t_hour,
    t.t_shift,
    s.ws_item_sk,
    s.ws_ext_sales_price,
    s.ws_net_paid,
    s.ws_net_profit,
    u.metric
  FROM tpcds.date_dim AS d
  FULL OUTER JOIN sales_sample AS s
    ON s.ws_sold_date_sk = d.d_date_sk
  INNER JOIN tpcds.time_dim AS t
    ON s.ws_sold_time_sk = t.t_time_sk
  CROSS JOIN UNNEST(s.metrics) AS u(metric)
  WHERE d.d_year = 2001
    AND d.d_month_seq = 12
    AND d.d_holiday = 'N'
    AND d.d_current_week = 'N'
    AND t.t_hour BETWEEN 9 AND 17
    AND t.t_shift = 'first'
    AND EXISTS (
      SELECT 1 FROM tpcds.time_dim td
      WHERE td.t_shift = t.t_shift AND td.t_hour = t.t_hour
    )
)
SELECT
  d_year,
  d_month_seq,
  d_holiday,
  d_current_week,
  t_hour,
  t_shift,
  ws_item_sk,
  metric,
  SUM(ws_ext_sales_price)   AS total_sales,
  AVG(ws_net_paid)          AS avg_net_paid,
  COUNT(*)                  AS txn_count,
  MIN(ws_net_profit)        AS min_profit,
  MAX(ws_net_profit)        AS max_profit
FROM joined_data
GROUP BY CUBE (d_year, d_month_seq, d_holiday, d_current_week, t_hour, t_shift, ws_item_sk, metric)
HAVING COUNT(*) > 0
LIMIT 100
