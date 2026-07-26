WITH cs_ordered AS (
  SELECT
    cs.cs_call_center_sk,
    cc.cc_name,
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_item_sk,
    i.i_item_id,
    i.i_category,
    LAG(cs.cs_net_profit) OVER (PARTITION BY cs.cs_call_center_sk ORDER BY cs.cs_order_number) AS prev_profit,
    SUM(cs.cs_net_profit) OVER (PARTITION BY cs.cs_call_center_sk ORDER BY cs.cs_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
)
SELECT
  cs_call_center_sk,
  cc_name,
  cs_order_number,
  i_item_id,
  i_category,
  cs_net_profit,
  prev_profit,
  cum_profit,
  CASE
    WHEN prev_profit IS NULL THEN 'First Order'
    WHEN cs_net_profit > prev_profit THEN 'Profit Up'
    WHEN cs_net_profit < prev_profit THEN 'Profit Down'
    ELSE 'Profit Same'
  END AS profit_trend,
  CASE
    WHEN cum_profit > 5000000 THEN 'High Cum Profit'
    WHEN cum_profit BETWEEN 1000000 AND 5000000 THEN 'Medium Cum Profit'
    ELSE 'Low Cum Profit'
  END AS cum_profit_category
FROM cs_ordered
WHERE cs_order_number BETWEEN 1000 AND 1100
ORDER BY cs_call_center_sk, cs_order_number
LIMIT 100
