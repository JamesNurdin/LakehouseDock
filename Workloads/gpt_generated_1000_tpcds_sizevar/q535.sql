SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_wholesale_cost,
    cr.cr_return_amount,
    cr.cr_net_loss
FROM tpcds.catalog_sales AS cs
JOIN tpcds.catalog_returns AS cr
  ON cs.cs_order_number = cr.cr_order_number
 AND cs.cs_item_sk = cr.cr_item_sk
WHERE cs.cs_wholesale_cost > 50
  AND cr.cr_warehouse_sk = 10
