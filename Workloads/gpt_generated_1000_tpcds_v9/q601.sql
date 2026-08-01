SELECT s.s_store_id,
       s.s_store_name,
       s.s_city,
       s.s_state,
       s.s_country,
       SUM(ss.ss_net_paid_inc_tax) AS total_sales
FROM store s
JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_country = 'United States'
  AND ss.ss_net_paid_inc_tax > 1500.0
GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state, s.s_country
ORDER BY total_sales DESC
