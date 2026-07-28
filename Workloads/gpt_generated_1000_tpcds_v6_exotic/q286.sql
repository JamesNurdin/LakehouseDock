WITH joined AS (
  SELECT
    cs.cs_net_paid,
    cs.cs_net_profit,
    td.t_hour,
    cp.cp_department,
    sm.sm_type,
    wr.wr_return_amt,
    c.c_birth_year
  FROM catalog_sales cs
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
  WHERE td.t_hour BETWEEN 9 AND 12
    AND cp.cp_department = 'Electronics'
    AND sm.sm_type = 'AIR'
    AND c.c_birth_year = 1980
    AND cs.cs_net_paid > 100
),
agg AS (
  SELECT
    cp_department,
    sm_type,
    COUNT(*) AS sales_cnt,
    SUM(cs_net_paid) AS total_sales,
    SUM(COALESCE(wr_return_amt, 0)) AS total_returns
  FROM joined
  GROUP BY cp_department, sm_type
)
SELECT
  cp_department,
  sm_type,
  sales_cnt,
  total_sales,
  total_returns,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
