SELECT
    s.s_store_name,
    s.s_market_manager,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(*) AS sales_count
FROM tpcds.store AS s
JOIN tpcds.store_sales AS ss
  ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
  AND ss.ss_store_sk = 721
GROUP BY s.s_store_name, s.s_market_manager
ORDER BY total_net_paid DESC
LIMIT 100
