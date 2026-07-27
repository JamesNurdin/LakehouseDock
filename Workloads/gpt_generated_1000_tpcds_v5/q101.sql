SELECT cr_item_sk,
       SUM(cr_return_quantity) AS total_return_qty,
       SUM(cr_return_amount) AS total_return_amount,
       SUM(cr_net_loss) AS total_net_loss
FROM tpcds.catalog_returns
WHERE cr_returning_customer_sk IN (2818973, 8836584)
  AND cr_refunded_cash > 500
GROUP BY cr_item_sk
ORDER BY total_net_loss DESC
LIMIT 100
