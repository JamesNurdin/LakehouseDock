SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_net_paid_inc_ship,
    cr.cr_return_amount,
    cr.cr_refunded_cash
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cs.cs_item_sk = cr.cr_item_sk
 AND cs.cs_order_number = cr.cr_order_number
WHERE cs.cs_ship_date_sk = 2450871
  AND cr.cr_refunded_cash > 5.00
ORDER BY cs.cs_net_paid_inc_ship DESC
LIMIT 100
