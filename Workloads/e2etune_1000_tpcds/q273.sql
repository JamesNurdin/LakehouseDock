SELECT
    sr.sr_store_sk AS store_id,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(*) AS return_count,
    (SUM(sr.sr_net_loss) / NULLIF(SUM(ss.ss_net_profit), 0)) AS loss_to_profit_ratio,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    RANK() OVER (ORDER BY (SUM(sr.sr_net_loss) / NULLIF(SUM(ss.ss_net_profit), 0)) DESC) AS loss_profit_rank
FROM store_returns sr
JOIN store_sales ss
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
WHERE sr.sr_returned_date_sk BETWEEN 2451915 AND 2452000
  AND ss.ss_sold_date_sk BETWEEN 2451915 AND 2452000
  AND sr.sr_store_credit > 50.00
  AND ss.ss_net_paid > 100.00
GROUP BY sr.sr_store_sk
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY loss_to_profit_ratio DESC
LIMIT 10
