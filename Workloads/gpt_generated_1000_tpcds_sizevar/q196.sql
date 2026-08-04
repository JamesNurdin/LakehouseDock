SELECT ss_ticket_number AS ticket_number
FROM tpcds.store_sales ss TABLESAMPLE BERNOULLI (10)
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE s.s_market_id = 6
  AND t.t_hour BETWEEN 9 AND 17

EXCEPT

SELECT sr_ticket_number AS ticket_number
FROM tpcds.store_returns sr
JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%Wrong size%'

ORDER BY ticket_number DESC
LIMIT 100
