WITH returns_by_dept_month AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month_num,
    cp.cp_department,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_quantity) AS avg_return_qty
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cp.cp_type = 'monthly'
    AND d.d_year BETWEEN 2000 AND 2002
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY d.d_year, d.d_moy, cp.cp_department
),
sales_by_month AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month_num,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy
)
SELECT
  r.year,
  r.month_num,
  r.cp_department,
  r.total_return_amount,
  r.return_cnt,
  r.avg_return_qty,
  s.total_net_paid,
  s.total_sales_price,
  s.sales_cnt,
  ROUND(((s.total_net_paid - r.total_return_amount) / NULLIF(s.total_net_paid, 0)) * 100, 2) AS profit_margin_pct
FROM returns_by_dept_month r
JOIN sales_by_month s
  ON r.year = s.year AND r.month_num = s.month_num
ORDER BY r.year, r.month_num, r.cp_department
