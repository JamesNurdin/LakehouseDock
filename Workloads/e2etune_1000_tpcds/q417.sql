SELECT
   s.s_store_id,
   s.s_store_name,
   s.s_city,
   s.s_state,
   ca.ca_zip,
   ss.ss_sold_date_sk AS sale_date_sk,
   SUM(ss.ss_net_paid) AS total_sales,
   SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
   SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit,
   CASE WHEN SUM(ss.ss_net_paid) = 0 THEN 0
        ELSE (SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) / SUM(ss.ss_net_paid)
   END AS profit_margin,
   COUNT(*) AS sales_txn,
   COUNT(sr.sr_ticket_number) AS return_txn,
   RANK() OVER (PARTITION BY s.s_city ORDER BY (SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) DESC) AS city_rank
FROM store_sales ss
JOIN store s
   ON s.s_store_sk = ss.ss_store_sk
JOIN customer_address ca
   ON ca.ca_address_sk = ss.ss_addr_sk
LEFT JOIN store_returns sr
   ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_store_sk = ss.ss_store_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
  AND ca.ca_state = 'CA'
GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state, ca.ca_zip, ss.ss_sold_date_sk
HAVING COUNT(*) >= 100
ORDER BY net_profit DESC
LIMIT 20
