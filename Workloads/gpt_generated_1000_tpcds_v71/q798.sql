WITH sales_returns_a AS (
  SELECT
    i.i_category,
    i.i_brand,
    td.t_hour,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns,
    SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax) AS net_revenue,
    CASE
      WHEN SUM(cs.cs_ext_sales_price) = 0 THEN 0
      ELSE (SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) / SUM(cs.cs_ext_sales_price)
    END AS net_margin
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE
    td.t_hour BETWEEN 9 AND 12
    AND i.i_category = 'Electronics'
    AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
    AND cc.cc_state = 'CA'
    AND ib.ib_lower_bound >= 50000
    AND cs.cs_net_paid > 1000
  GROUP BY i.i_category, i.i_brand, td.t_hour
),

sales_returns_b AS (
  SELECT
    i.i_category,
    i.i_brand,
    td.t_hour,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns,
    SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax) AS net_revenue,
    CASE
      WHEN SUM(cs.cs_ext_sales_price) = 0 THEN 0
      ELSE (SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) / SUM(cs.cs_ext_sales_price)
    END AS net_margin
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE
    td.t_hour BETWEEN 13 AND 17
    AND i.i_category = 'Electronics'
    AND r.r_reason_id = 'AAAAAAAHAAAAAAA'
    AND cc.cc_state = 'CA'
    AND ib.ib_lower_bound >= 50000
    AND cs.cs_net_paid > 1000
  GROUP BY i.i_category, i.i_brand, td.t_hour
),

combined AS (
  SELECT * FROM sales_returns_a
  UNION ALL
  SELECT * FROM sales_returns_b
)
SELECT
  i_category,
  i_brand,
  t_hour,
  total_sales,
  total_returns,
  net_revenue,
  net_margin,
  RANK() OVER (PARTITION BY i_category ORDER BY net_revenue DESC) AS revenue_rank,
  CASE
    WHEN net_margin >= 0.20 THEN 'HIGH_MARGIN'
    WHEN net_margin >= 0.10 THEN 'MEDIUM_MARGIN'
    ELSE 'LOW_MARGIN'
  END AS margin_category
FROM combined
ORDER BY i_category, revenue_rank
LIMIT 100
