WITH sales_by_hh AS (
  SELECT ss.ss_hdemo_sk AS hd_demo_sk,
         SUM(ss.ss_net_profit) AS total_sales_profit,
         COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers_sales,
         AVG(ss.ss_quantity) AS avg_quantity_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ss.ss_hdemo_sk
),
 returns_by_hh AS (
  SELECT cr.cr_refunded_hdemo_sk AS hd_demo_sk,
         SUM(cr.cr_net_loss) AS total_return_loss,
         COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_customers_returns,
         AVG(cr.cr_return_quantity) AS avg_quantity_returns
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY cr.cr_refunded_hdemo_sk
)
SELECT hd.hd_demo_sk,
       hd.hd_income_band_sk,
       hd.hd_vehicle_count,
       COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_contribution,
       (COALESCE(s.distinct_customers_sales, 0) + COALESCE(r.distinct_customers_returns, 0)) AS total_customers,
       CASE
         WHEN (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) >= 5000 THEN 'High Contributor'
         WHEN (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) BETWEEN 0 AND 5000 THEN 'Medium Contributor'
         ELSE 'Low/Negative Contributor'
       END AS contribution_category,
       ROW_NUMBER() OVER (ORDER BY (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) DESC) AS revenue_rank
FROM household_demographics hd
LEFT JOIN sales_by_hh s ON hd.hd_demo_sk = s.hd_demo_sk
LEFT JOIN returns_by_hh r ON hd.hd_demo_sk = r.hd_demo_sk
WHERE hd.hd_vehicle_count IS NOT NULL
ORDER BY net_contribution DESC
LIMIT 15
