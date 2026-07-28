SELECT cr_order_number,
       cr_return_amount,
       cr_refunded_cash,
       cr_return_quantity
FROM catalog_returns
WHERE cr_refunded_cash > 1000
  AND cr_return_quantity = 1
ORDER BY cr_refunded_cash DESC
