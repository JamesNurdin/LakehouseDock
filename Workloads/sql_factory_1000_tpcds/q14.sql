WITH weekly_sales AS (
  SELECT d.d_week_seq,
         MIN(d.d_date) AS week_start_date,
         SUM(ss.ss_net_profit) AS week_sales_profit,
         AVG(hd.hd_vehicle_count) AS avg_vehicle_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  GROUP BY d.d_week_seq
),
 weekly_returns AS (
  SELECT d.d_week_seq,
         SUM(cr.cr_net_loss) AS week_return_loss,
         AVG(hd.hd_vehicle_count) AS avg_vehicle_returns
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  GROUP BY d.d_week_seq
),
 weekly_combined AS (
  SELECT s.d_week_seq,
         s.week_start_date,
         s.week_sales_profit,
         r.week_return_loss,
         s.avg_vehicle_sales,
         r.avg_vehicle_returns,
         (s.week_sales_profit - COALESCE(r.week_return_loss, 0)) AS net_week_impact
  FROM weekly_sales s
  LEFT JOIN weekly_returns r ON s.d_week_seq = r.d_week_seq
)
SELECT wc.d_week_seq,
       wc.week_start_date,
       wc.week_sales_profit,
       wc.week_return_loss,
       wc.net_week_impact,
       LAG(wc.net_week_impact) OVER (ORDER BY wc.d_week_seq) AS prev_week_impact,
       (wc.net_week_impact - LAG(wc.net_week_impact) OVER (ORDER BY wc.d_week_seq)) AS week_delta,
       CASE WHEN (wc.net_week_impact - LAG(wc.net_week_impact) OVER (ORDER BY wc.d_week_seq)) > 10000 THEN 'Significant Increase' ELSE 'Stable/Decrease' END AS impact_trend,
       PERCENT_RANK() OVER (ORDER BY wc.net_week_impact DESC) AS profit_percent_rank
FROM weekly_combined wc
WHERE wc.d_week_seq BETWEEN 1000 AND 2000
ORDER BY wc.d_week_seq
LIMIT 25
