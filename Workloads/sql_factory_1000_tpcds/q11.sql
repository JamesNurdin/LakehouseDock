WITH sales_quarter AS (
  SELECT d.d_quarter_seq,
         d.d_year,
         SUM(ss.ss_ext_sales_price) AS total_sales_amount,
         SUM(ss.ss_net_profit) AS total_sales_profit,
         AVG(hd.hd_vehicle_count) AS avg_vehicle_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  GROUP BY d.d_quarter_seq, d.d_year
),
 returns_quarter AS (
  SELECT d.d_quarter_seq,
         d.d_year,
         SUM(cr.cr_return_amount) AS total_return_amount,
         SUM(cr.cr_net_loss) AS total_return_loss,
         AVG(hd.hd_vehicle_count) AS avg_vehicle_returns
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  GROUP BY d.d_quarter_seq, d.d_year
),
 quarter_combined AS (
  SELECT s.d_quarter_seq,
         s.d_year,
         s.total_sales_amount,
         s.total_sales_profit,
         r.total_return_amount,
         r.total_return_loss,
         (s.total_sales_amount - COALESCE(r.total_return_amount, 0)) AS net_sales_amount,
         (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) AS net_profit,
         CASE
           WHEN s.total_sales_amount = 0 THEN NULL
           ELSE (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) / s.total_sales_amount
         END AS profit_margin,
         CASE
           WHEN (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) > 0 THEN 'Profitable'
           ELSE 'Loss'
         END AS quarter_status,
         DENSE_RANK() OVER (ORDER BY (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
  FROM sales_quarter s
  LEFT JOIN returns_quarter r ON s.d_quarter_seq = r.d_quarter_seq AND s.d_year = r.d_year
)
SELECT d_quarter_seq,
       d_year,
       total_sales_amount,
       total_return_amount,
       net_sales_amount,
       net_profit,
       profit_margin,
       quarter_status,
       profit_rank
FROM quarter_combined
WHERE d_year BETWEEN 1999 AND 2002
ORDER BY profit_rank
LIMIT 12
