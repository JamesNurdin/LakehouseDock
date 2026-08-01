SELECT
  cr.cr_order_number,
  cr.cr_return_amount,
  cs.cs_ext_tax,
  cs.cs_net_profit
FROM catalog_returns AS cr
JOIN catalog_sales AS cs
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
WHERE cr.cr_returning_customer_sk = 3753188
  AND cs.cs_ship_hdemo_sk = 4052
LIMIT 100
