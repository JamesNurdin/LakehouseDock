SELECT i.inv_item_sk,
       i.inv_warehouse_sk,
       i.inv_date_sk,
       SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
       COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_quantity,
       SUM(i.inv_quantity_on_hand) - COALESCE(SUM(wr.wr_return_quantity), 0) AS net_quantity,
       COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amount_inc_tax,
       AVG(wr.wr_return_amt_inc_tax) AS avg_return_amount_inc_tax,
       COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM inventory i
LEFT JOIN web_returns wr
  ON i.inv_item_sk = wr.wr_item_sk
 AND i.inv_date_sk = wr.wr_returned_date_sk
WHERE i.inv_quantity_on_hand > 0
  AND i.inv_date_sk BETWEEN 2450815 AND 2451053
GROUP BY i.inv_item_sk, i.inv_warehouse_sk, i.inv_date_sk
HAVING SUM(i.inv_quantity_on_hand) > 100
ORDER BY net_quantity DESC
LIMIT 100
