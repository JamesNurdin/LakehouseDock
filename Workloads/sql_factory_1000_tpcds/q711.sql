WITH profit_by_cc_gender AS (
  SELECT
    cc.cc_name,
    cd_bill.cd_gender,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS total_orders
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  GROUP BY cc.cc_name, cd_bill.cd_gender
)
SELECT
  cc_name,
  cd_gender,
  total_profit,
  total_orders,
  CASE
    WHEN total_profit > 1000000 THEN 'High'
    WHEN total_profit > 500000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_cc_gender
WHERE total_profit > 0
ORDER BY profit_rank
