WITH sales_agg AS (
  SELECT
    cp.cp_department,
    d1.d_year,
    SUM(cs.cs_net_profit) AS dept_year_profit,
    COUNT(*) AS txn_cnt,
    AVG(cs.cs_net_paid) AS avg_paid,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs.cs_net_profit) DESC) AS dept_rank
  FROM catalog_sales cs
  JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
  JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store s ON s.s_closed_date_sk = d1.d_date_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    AND cr.cr_returned_date_sk = d1.d_date_sk
  WHERE d1.d_year = 2002
    AND cp.cp_department = 'Electronics'
    AND ib.ib_lower_bound >= 50000
    AND p.p_discount_active = 'Y'
    AND t1.t_am_pm = 'PM'
  GROUP BY cp.cp_department, d1.d_year
)
SELECT
  sa.cp_department,
  sa.d_year,
  sa.dept_year_profit,
  sa.txn_cnt,
  sa.avg_paid,
  sa.dept_rank,
  (SELECT AVG(dept_year_profit) FROM sales_agg) AS avg_dept_profit_overall
FROM sales_agg sa
WHERE sa.dept_year_profit > (SELECT AVG(dept_year_profit) FROM sales_agg)
ORDER BY sa.dept_year_profit DESC
LIMIT 100
