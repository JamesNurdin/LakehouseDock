SELECT
    sr.sr_store_sk AS store_id,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM tpcds.store_returns AS sr
JOIN tpcds.store_sales AS ss
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
WHERE sr.sr_return_ship_cost > 100.00
  AND ss.ss_sales_price < 50.00
GROUP BY sr.sr_store_sk
ORDER BY total_net_loss DESC
LIMIT 100
