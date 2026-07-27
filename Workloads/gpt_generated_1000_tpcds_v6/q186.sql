WITH sales_agg AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    hd.hd_vehicle_count,
    ca.ca_state,
    SUM(cs.cs_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(CASE WHEN sr.sr_return_quantity IS NOT NULL THEN sr.sr_return_quantity ELSE 0 END) AS total_store_returns,
    SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_quantity ELSE 0 END) AS total_web_returns
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk AND sr.sr_addr_sk = ca.ca_address_sk
  LEFT JOIN web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk AND wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE cc.cc_state = 'CA'
    AND cp.cp_department = 'Books'
    AND sm.sm_type = 'AIR'
    AND cs.cs_quantity > 5
  GROUP BY
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    hd.hd_vehicle_count,
    ca.ca_state
  HAVING SUM(cs.cs_sales_price) > 1000
)
SELECT
  cs_order_number,
  cs_sold_date_sk,
  cc_name,
  cp_department,
  sm_type,
  w_warehouse_name,
  hd_vehicle_count,
  ca_state,
  total_sales,
  total_profit,
  total_store_returns,
  total_web_returns,
  RANK() OVER (PARTITION BY cp_department ORDER BY total_sales DESC) AS dept_sales_rank,
  ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS overall_profit_rank,
  CASE WHEN total_store_returns > total_web_returns THEN 'Store' ELSE 'Web' END AS higher_return_source
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
