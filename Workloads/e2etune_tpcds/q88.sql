WITH sales_agg AS (
  SELECT
    cp.cp_department,
    d.d_year,
    d.d_moy AS month,
    sm.sm_type,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cp.cp_type = 'monthly'
    AND d.d_year BETWEEN 2001 AND 2003
  GROUP BY cp.cp_department, d.d_year, d.d_moy, sm.sm_type
),
store_ret_agg AS (
  SELECT
    d_ret.d_year,
    d_ret.d_moy AS month,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(sr.sr_return_quantity) AS total_store_return_qty
  FROM store_returns sr
  JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  WHERE d_ret.d_year BETWEEN 2001 AND 2003
  GROUP BY d_ret.d_year, d_ret.d_moy
),
web_ret_agg AS (
  SELECT
    d_ret.d_year,
    d_ret.d_moy AS month,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(wr.wr_return_quantity) AS total_web_return_qty
  FROM web_returns wr
  JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
  WHERE d_ret.d_year BETWEEN 2001 AND 2003
  GROUP BY d_ret.d_year, d_ret.d_moy
),
combined AS (
  SELECT
    s.cp_department,
    s.d_year,
    s.month,
    s.sm_type,
    s.total_sales,
    s.total_discount,
    s.total_profit,
    s.sales_cnt,
    COALESCE(sr.total_store_return_loss, 0) AS store_return_loss,
    COALESCE(wr.total_web_return_loss, 0) AS web_return_loss,
    (s.total_profit - COALESCE(sr.total_store_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0)) AS net_profit_after_returns
  FROM sales_agg s
  LEFT JOIN store_ret_agg sr
    ON s.d_year = sr.d_year AND s.month = sr.month
  LEFT JOIN web_ret_agg wr
    ON s.d_year = wr.d_year AND s.month = wr.month
)
SELECT
  cp_department,
  d_year,
  month,
  sm_type,
  total_sales,
  total_discount,
  total_profit,
  store_return_loss,
  web_return_loss,
  net_profit_after_returns,
  total_sales / NULLIF(sales_cnt, 0) AS avg_sale_per_transaction,
  LAG(net_profit_after_returns) OVER (PARTITION BY cp_department ORDER BY d_year, month) AS prev_month_profit,
  net_profit_after_returns - LAG(net_profit_after_returns) OVER (PARTITION BY cp_department ORDER BY d_year, month) AS profit_change,
  CASE
    WHEN LAG(net_profit_after_returns) OVER (PARTITION BY cp_department ORDER BY d_year, month) IS NOT NULL
      THEN (net_profit_after_returns - LAG(net_profit_after_returns) OVER (PARTITION BY cp_department ORDER BY d_year, month))
           / LAG(net_profit_after_returns) OVER (PARTITION BY cp_department ORDER BY d_year, month) * 100
    ELSE NULL
  END AS profit_change_pct
FROM combined
WHERE net_profit_after_returns > 0
ORDER BY cp_department, d_year, month
LIMIT 200
