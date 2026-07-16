WITH latest_fy AS (
  SELECT MAX(d_fy_year) AS max_fy_year FROM date_dim
),
latest_quarter AS (
  SELECT MAX(d_fy_quarter_seq) AS max_fq_seq
  FROM date_dim
  WHERE d_fy_year = (SELECT max_fy_year FROM latest_fy)
),
quarter_dates AS (
  SELECT d_date_sk, d_month_seq
  FROM date_dim
  WHERE d_fy_year = (SELECT max_fy_year FROM latest_fy)
    AND d_fy_quarter_seq = (SELECT max_fq_seq FROM latest_quarter)
),
store_monthly_profit AS (
  SELECT s.ss_store_sk,
         d.d_month_seq,
         SUM(s.ss_net_profit) AS monthly_net_profit
  FROM store_sales s
  JOIN quarter_dates d ON s.ss_sold_date_sk = d.d_date_sk
  GROUP BY s.ss_store_sk, d.d_month_seq
),
store_quarter_profit AS (
  SELECT ss_store_sk,
         SUM(monthly_net_profit) AS quarter_net_profit,
         AVG(monthly_net_profit) AS avg_monthly_profit
  FROM store_monthly_profit
  GROUP BY ss_store_sk
),
ranked_stores AS (
  SELECT ss_store_sk,
         quarter_net_profit,
         avg_monthly_profit,
         RANK() OVER (ORDER BY quarter_net_profit DESC) AS profit_rank
  FROM store_quarter_profit
),
store_monthly_growth AS (
  SELECT ss_store_sk,
         d_month_seq,
         monthly_net_profit,
         LAG(monthly_net_profit) OVER (PARTITION BY ss_store_sk ORDER BY d_month_seq) AS prev_month_profit,
         CASE WHEN LAG(monthly_net_profit) OVER (PARTITION BY ss_store_sk ORDER BY d_month_seq) IS NULL THEN NULL
              ELSE (monthly_net_profit - LAG(monthly_net_profit) OVER (PARTITION BY ss_store_sk ORDER BY d_month_seq))
                   / LAG(monthly_net_profit) OVER (PARTITION BY ss_store_sk ORDER BY d_month_seq) * 100
         END AS mom_growth_pct
  FROM store_monthly_profit
)
SELECT r.ss_store_sk,
       r.quarter_net_profit,
       r.avg_monthly_profit,
       r.profit_rank,
       g.d_month_seq,
       g.monthly_net_profit,
       g.mom_growth_pct
FROM ranked_stores r
JOIN store_monthly_growth g ON r.ss_store_sk = g.ss_store_sk
WHERE r.profit_rank <= 5
ORDER BY r.profit_rank, g.d_month_seq
