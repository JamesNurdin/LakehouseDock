SELECT
    r.sr_store_sk,
    COUNT(DISTINCT r.sr_ticket_number) AS num_transactions,
    SUM(r.sr_return_amt) AS total_return_amount,
    SUM(s.ss_ext_sales_price) AS total_sales_price,
    SUM(s.ss_net_profit) AS total_net_profit
FROM tpcds.store_returns r
JOIN tpcds.store_sales s
  ON r.sr_item_sk = s.ss_item_sk
  AND r.sr_ticket_number = s.ss_ticket_number
WHERE r.sr_store_sk = 308
  AND r.sr_return_ship_cost > 1000
GROUP BY r.sr_store_sk
ORDER BY total_return_amount DESC
