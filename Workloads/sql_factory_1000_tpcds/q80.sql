WITH sales_agg AS (
  SELECT ss_store_sk, SUM(ss_net_profit) AS total_sales_profit
  FROM store_sales
  GROUP BY ss_store_sk
),
returns_agg AS (
  SELECT sr_store_sk, SUM(sr_net_loss) AS total_return_loss
  FROM store_returns
  GROUP BY sr_store_sk
)
SELECT s.s_store_id,
       s.s_store_name,
       COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0) AS net_contribution,
       RANK() OVER (ORDER BY COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0) DESC) AS profit_rank
FROM store s
LEFT JOIN sales_agg sa ON s.s_store_sk = sa.ss_store_sk
LEFT JOIN returns_agg ra ON s.s_store_sk = ra.sr_store_sk
WHERE COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0) IS NOT NULL
ORDER BY net_contribution DESC
LIMIT 5
