SELECT c.c_customer_id,
       s.s_store_id,
       COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
       SUM(ss.ss_net_paid) AS total_paid,
       COALESCE(SUM(sr.sr_refunded_cash), 0) AS total_refunds,
       SUM(ss.ss_net_paid) - COALESCE(SUM(sr.sr_refunded_cash), 0) AS net_cash_flow,
       CASE WHEN SUM(ss.ss_net_paid) - COALESCE(SUM(sr.sr_refunded_cash), 0) > 5000 THEN 'HIGH' ELSE 'LOW' END AS spend_category,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_paid) - COALESCE(SUM(sr.sr_refunded_cash), 0) DESC) AS cash_flow_rank
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                         AND sr.sr_store_sk = s.s_store_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
WHERE s.s_state = 'TX' AND c.c_birth_year BETWEEN 1970 AND 1990
GROUP BY c.c_customer_id, s.s_store_id
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY s.s_store_id, net_cash_flow DESC
