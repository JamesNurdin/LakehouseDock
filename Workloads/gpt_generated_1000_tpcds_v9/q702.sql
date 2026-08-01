SELECT cr.cr_order_number,
       cr.cr_return_amount,
       cs.cs_net_paid_inc_ship,
       cs.cs_wholesale_cost
FROM catalog_returns cr
JOIN catalog_sales cs ON cr.cr_item_sk = cs.cs_item_sk
WHERE cr.cr_fee > 30
  AND cs.cs_wholesale_cost < 50
ORDER BY cr.cr_return_amount DESC
LIMIT 100
