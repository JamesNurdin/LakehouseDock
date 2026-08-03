SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cs.cs_ext_sales_price,
    cs.cs_net_profit
FROM catalog_returns AS cr
JOIN catalog_sales AS cs
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
WHERE cr.cr_return_amount > 1000
  AND cs.cs_wholesale_cost < 40
