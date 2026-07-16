SELECT d.d_year,
       d.d_month_seq,
       i.i_category,
       s.s_state,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS total_orders
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year, d.d_month_seq, i.i_category, s.s_state
ORDER BY d.d_year, d.d_month_seq, total_sales DESC
LIMIT 100
