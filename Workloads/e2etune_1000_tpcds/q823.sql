SELECT
    s.ss_store_sk AS store_id,
    SUM(s.ss_net_paid) AS total_sales,
    SUM(r.sr_return_amt) AS total_returns,
    SUM(s.ss_net_profit) AS total_profit,
    SUM(r.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT s.ss_ticket_number) AS sales_transactions,
    COUNT(DISTINCT r.sr_ticket_number) AS return_transactions,
    AVG(s.ss_quantity) AS avg_quantity,
    AVG(r.sr_return_quantity) AS avg_return_qty,
    CAST(SUM(r.sr_net_loss) AS double) / NULLIF(SUM(s.ss_net_paid), 0) AS loss_ratio,
    RANK() OVER (ORDER BY CAST(SUM(r.sr_net_loss) AS double) / NULLIF(SUM(s.ss_net_paid), 0) DESC) AS loss_rank
FROM store_returns r
JOIN store_sales s
  ON r.sr_item_sk = s.ss_item_sk
 AND r.sr_ticket_number = s.ss_ticket_number
WHERE r.sr_returned_date_sk BETWEEN 2452000 AND 2453000
  AND s.ss_sold_date_sk BETWEEN 2452000 AND 2453000
  AND r.sr_store_sk IN (118, 727, 140, 112, 253)
GROUP BY s.ss_store_sk
HAVING SUM(s.ss_net_paid) > 0
ORDER BY loss_ratio DESC
LIMIT 10
