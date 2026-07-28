WITH enriched AS (
   SELECT
     cc.cc_call_center_sk,
     cc.cc_name,
     cc.cc_manager,
     cc.cc_mkt_desc,
     hd.hd_buy_potential,
     d.d_year,
     t.t_hour,
     cs.cs_net_paid_inc_ship,
     cs.cs_quantity
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2002
     AND regexp_like(cc.cc_mkt_desc, '(?i)development|dangerous')
     AND cc.cc_manager LIKE '%Bob%'
     AND hd.hd_buy_potential LIKE 'HIGH%'
),
aggregated AS (
   SELECT
     cc_call_center_sk,
     cc_name,
     cc_manager,
     cc_mkt_desc,
     d_year,
     t_hour,
     SUM(cs_net_paid_inc_ship) AS total_sales,
     SUM(cs_quantity) AS total_qty,
     COUNT(*) AS sales_cnt,
     CONCAT(SUBSTRING(cc_manager, 1, 1), '. ', SUBSTRING(cc_name, 1, 10)) AS manager_name_snippet,
     regexp_extract(cc_mkt_desc, '(\\w+)', 1) AS mkt_first_word
   FROM enriched
   GROUP BY
     cc_call_center_sk,
     cc_name,
     cc_manager,
     cc_mkt_desc,
     d_year,
     t_hour
)
SELECT
  cc_call_center_sk,
  cc_name,
  cc_manager,
  cc_mkt_desc,
  manager_name_snippet,
  mkt_first_word,
  d_year,
  t_hour,
  total_sales,
  total_qty,
  sales_cnt,
  ROW_NUMBER() OVER (PARTITION BY t_hour ORDER BY total_sales DESC) AS sales_rank_in_hour
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
