SELECT s.s_store_id,
       ss.ss_item_sk AS item_sk,
       SUM(ss.ss_quantity) AS total_sales_qty,
       COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_qty,
       CASE 
         WHEN SUM(ss.ss_quantity) = 0 THEN 0
         ELSE COALESCE(SUM(sr.sr_return_quantity), 0) * 100.0 / SUM(ss.ss_quantity)
       END AS return_rate_pct,
       CASE 
         WHEN COALESCE(SUM(sr.sr_return_quantity), 0) * 1.0 / NULLIF(SUM(ss.ss_quantity), 0) > 0.30 THEN 'Potential Issue'
         ELSE 'Normal'
       END AS issue_flag,
       DENSE_RANK() OVER (PARTITION BY s.s_store_sk ORDER BY 
         CASE 
           WHEN SUM(ss.ss_quantity) = 0 THEN 0
           ELSE COALESCE(SUM(sr.sr_return_quantity), 0) * 1.0 / SUM(ss.ss_quantity)
         END DESC) AS return_rate_rank
FROM store s
JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN store_returns sr 
  ON s.s_store_sk = sr.sr_store_sk 
 AND ss.ss_item_sk = sr.sr_item_sk
GROUP BY s.s_store_id, s.s_store_sk, ss.ss_item_sk
HAVING SUM(ss.ss_quantity) > 0
ORDER BY s.s_store_id, return_rate_rank
