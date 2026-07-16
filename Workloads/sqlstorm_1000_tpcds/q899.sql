WITH sales_agg AS (
 SELECT
   s.s_store_id,
   d.d_year,
   d.d_month_seq,
   SUM(ss.ss_net_profit) AS total_profit,
   SUM(ss.ss_net_paid) AS total_paid,
   COUNT(*) AS sales_count
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 WHERE d.d_year = 2002
 GROUP BY s.s_store_id, d.d_year, d.d_month_seq
),
returns_agg AS (
 SELECT
   s.s_store_id,
   d.d_year,
   d.d_month_seq,
   SUM(sr.sr_net_loss) AS total_loss,
   COUNT(*) AS return_count
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN store s ON sr.sr_store_sk = s.s_store_sk
 WHERE d.d_year = 2002
 GROUP BY s.s_store_id, d.d_year, d.d_month_seq
),
combined AS (
 SELECT
   COALESCE(sa.s_store_id, ra.s_store_id) AS store_id,
   COALESCE(sa.d_year, ra.d_year) AS year,
   COALESCE(sa.d_month_seq, ra.d_month_seq) AS month_seq,
   COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0) AS net_profit,
   COALESCE(sa.sales_count, 0) AS sales_count,
   COALESCE(ra.return_count, 0) AS return_count
 FROM sales_agg sa
 FULL OUTER JOIN returns_agg ra
   ON sa.s_store_id = ra.s_store_id
  AND sa.d_year = ra.d_year
  AND sa.d_month_seq = ra.d_month_seq
)
SELECT
  store_id,
  year,
  month_seq,
  net_profit,
  sales_count,
  return_count,
  RANK() OVER (ORDER BY net_profit DESC) AS profit_rank
FROM combined
WHERE net_profit IS NOT NULL
ORDER BY net_profit DESC
LIMIT 100
