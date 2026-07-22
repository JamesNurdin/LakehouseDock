SELECT
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS location,
    regexp_extract(s.s_manager, '\\w+', 1) AS manager_first_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_transactions
FROM store s
JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND regexp_like(s.s_manager, 'Ward')
  AND s.s_city LIKE '%York%'
GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state, s.s_manager
HAVING SUM(ss.ss_net_profit) > (
    SELECT avg(ss2.ss_net_profit)
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2002
)
ORDER BY total_net_profit DESC
LIMIT 100
