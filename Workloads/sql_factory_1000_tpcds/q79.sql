WITH manager_sales AS (
  SELECT s.s_manager AS manager,
         SUM(ss.ss_net_profit) AS total_profit
  FROM store s
  JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
  GROUP BY s.s_manager
),
 manager_returns AS (
  SELECT s.s_manager AS manager,
         SUM(sr.sr_net_loss) AS total_loss
  FROM store s
  JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
  GROUP BY s.s_manager
)
SELECT ms.manager,
       ms.total_profit,
       COALESCE(mr.total_loss, 0) AS total_loss,
       CASE 
         WHEN (ms.total_profit + COALESCE(mr.total_loss, 0)) = 0 THEN 0
         ELSE ms.total_profit / (ms.total_profit + COALESCE(mr.total_loss, 0))
       END AS profit_margin,
       CASE 
         WHEN (ms.total_profit / (ms.total_profit + COALESCE(mr.total_loss, 0))) >= 0.75 THEN 'Excellent'
         WHEN (ms.total_profit / (ms.total_profit + COALESCE(mr.total_loss, 0))) >= 0.5 THEN 'Good'
         ELSE 'Poor'
       END AS performance_category,
       RANK() OVER (ORDER BY 
         CASE 
           WHEN (ms.total_profit + COALESCE(mr.total_loss, 0)) = 0 THEN 0
           ELSE ms.total_profit / (ms.total_profit + COALESCE(mr.total_loss, 0))
         END DESC) AS manager_rank
FROM manager_sales ms
LEFT JOIN manager_returns mr ON ms.manager = mr.manager
ORDER BY manager_rank
