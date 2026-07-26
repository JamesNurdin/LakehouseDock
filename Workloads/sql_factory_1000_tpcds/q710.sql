WITH daily_item_profit AS (
  SELECT
    cc.cc_name,
    i.i_category,
    cs.cs_sold_date_sk,
    i.i_item_id,
    SUM(cs.cs_net_profit) AS daily_profit,
    SUM(cs.cs_quantity) AS daily_quantity
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  GROUP BY cc.cc_name, i.i_category, cs.cs_sold_date_sk, i.i_item_id
)
SELECT
  cc_name,
  i_category,
  cs_sold_date_sk,
  i_item_id,
  daily_profit,
  daily_quantity,
  profit_rank
FROM (
  SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY cc_name, i_category, cs_sold_date_sk ORDER BY daily_profit DESC) AS profit_rank
  FROM daily_item_profit
) t
WHERE profit_rank <= 3
ORDER BY cc_name, i_category, cs_sold_date_sk, profit_rank
