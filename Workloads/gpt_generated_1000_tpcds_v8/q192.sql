WITH sales_data AS (
  SELECT
    i.i_brand,
    s.s_state,
    cs.cs_net_profit,
    ss.ss_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
  JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE i.i_brand = 'Brand#12'
    AND s.s_state = 'CA'
    AND sm.sm_carrier = 'USPS'
    AND ws.web_county = 'Mobile County'
    AND d.d_year = 2001
    AND cp.cp_type = 'A'
),
agg AS (
  SELECT
    i_brand,
    s_state,
    SUM(cs_net_profit) AS cat_profit,
    SUM(ss_net_profit) AS store_profit,
    SUM(cs_net_profit) + SUM(ss_net_profit) AS total_profit
  FROM sales_data
  GROUP BY GROUPING SETS (
    (i_brand, s_state),
    (i_brand),
    (s_state),
    ()
  )
)
SELECT
  i_brand,
  s_state,
  cat_profit,
  store_profit,
  total_profit,
  ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS brand_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
