SELECT d.d_year,
       s.s_state,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(ss.ss_ticket_number) AS ticket_count
FROM store_sales ss
INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 1905 AND s.s_state = 'NC'
GROUP BY d.d_year, s.s_state
