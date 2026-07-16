WITH monthly_profit AS (
  SELECT
    cc.cc_division AS division,
    d.d_year,
    d.d_month_seq AS month,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cc.cc_gmt_offset = -6.00
    AND d.d_year = 2020
    AND cp.cp_type = 'Electronics'
  GROUP BY cc.cc_division, d.d_year, d.d_month_seq
  HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
  division,
  d_year,
  month,
  total_net_profit,
  total_quantity,
  avg_discount,
  RANK() OVER (PARTITION BY d_year, month ORDER BY total_net_profit DESC) AS profit_rank
FROM monthly_profit
ORDER BY d_year, month, profit_rank
