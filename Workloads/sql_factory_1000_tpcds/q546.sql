SELECT i.i_category,
       SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_quantity ELSE 0 END) AS total_return_qty,
       SUM(sr.sr_return_amt) AS total_store_return_amt,
       COUNT(DISTINCT ws.ws_order_number) AS web_orders,
       MAX(ws.ws_net_profit) AS max_net_profit,
       RANK() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS loss_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk BETWEEN 20200101 AND 20201231
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk BETWEEN 20200101 AND 20201231
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_category = 'Books'
GROUP BY i.i_category
ORDER BY loss_rank
OFFSET 2 ROWS FETCH NEXT 4 ROWS ONLY
