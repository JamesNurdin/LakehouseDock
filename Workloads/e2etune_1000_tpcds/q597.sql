SELECT
    cp.cp_type,
    s.s_state,
    t.t_shift,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_net_paid) AS avg_net_paid,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_type ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN catalog_page cp
  ON ss.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
WHERE cp.cp_type = 'quarterly'
  AND s.s_state = 'CA'
  AND c.c_birth_country = 'United States'
  AND t.t_shift = 'Evening'
GROUP BY cp.cp_type, s.s_state, t.t_shift
HAVING SUM(ss.ss_quantity) > 100
ORDER BY total_net_profit DESC
LIMIT 50
