/*
  goal: Summarize sales performance by manufacturer, warehouse state, and hour of day, applying realistic selective filters on product, cost, warehouse size, and time.
*/
SELECT
  i.i_manufact AS manufacturer,
  w.w_state AS warehouse_state,
  t.t_hour AS hour_of_day,
  SUM(cs.cs_ext_sales_price) AS total_sales_amount,
  SUM(cs.cs_quantity) AS total_quantity_sold,
  AVG(cs.cs_net_profit) AS avg_net_profit,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  MIN(cs.cs_ext_discount_amt) AS min_discount_amount,
  MAX(cs.cs_ext_discount_amt) AS max_discount_amount
FROM catalog_sales cs
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE i.i_manufact = 'antiablecally'
  AND i.i_class_id IN (1, 4)
  AND cs.cs_ext_wholesale_cost > 1000.00
  AND w.w_warehouse_sq_ft BETWEEN 600000 AND 700000
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY i.i_manufact, w.w_state, t.t_hour
ORDER BY total_sales_amount DESC
LIMIT 100
