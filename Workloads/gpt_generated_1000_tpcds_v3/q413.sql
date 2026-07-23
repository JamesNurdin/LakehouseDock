WITH raw AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_street_type,
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    wp.wp_web_page_sk,
    wp.wp_type,
    wp.wp_char_count,
    cs.cs_order_number,
    cs.cs_ext_sales_price AS cs_sales_price,
    cs.cs_net_profit AS cs_net_profit,
    cs.cs_quantity,
    ws.ws_order_number,
    ws.ws_ext_sales_price AS ws_sales_price,
    ws.ws_net_profit AS ws_net_profit,
    ws.ws_ext_tax,
    wr.wr_return_amt,
    wr.wr_net_loss,
    CASE WHEN cs.cs_ext_sales_price > 3000 THEN 'High' ELSE 'Low' END AS cs_sales_category,
    CASE WHEN ws.ws_ext_sales_price > 3000 THEN 'High' ELSE 'Low' END AS ws_sales_category
  FROM call_center cc
  JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
  JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE cc.cc_employees > 5000000
    AND cc.cc_street_type IN ('Road', 'Pkwy')
    AND hd.hd_vehicle_count >= 2
    AND ws.ws_ext_tax > 30
    AND ws.ws_ext_sales_price BETWEEN 1000 AND 5000
    AND cs.cs_quantity BETWEEN 1 AND 5
    AND wr.wr_return_amt > 50
),
aggregated AS (
  SELECT
    cc_name,
    cc_street_type,
    hd_vehicle_count,
    wp_type,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_sales_price) AS total_catalog_sales,
    SUM(ws_sales_price) AS total_web_sales,
    SUM(cs_sales_price + ws_sales_price) AS total_combined_sales,
    SUM(cs_net_profit) AS total_catalog_profit,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(wr_return_amt) AS total_returns,
    AVG(ws_ext_tax) AS avg_web_tax,
    CASE
      WHEN SUM(cs_sales_price + ws_sales_price) > 100000 THEN 'Very High'
      WHEN SUM(cs_sales_price + ws_sales_price) > 50000 THEN 'High'
      ELSE 'Medium'
    END AS sales_volume_category
  FROM raw
  GROUP BY
    cc_name,
    cc_street_type,
    hd_vehicle_count,
    wp_type
)
SELECT
  cc_name,
  cc_street_type,
  hd_vehicle_count,
  wp_type,
  distinct_orders,
  total_catalog_sales,
  total_web_sales,
  total_combined_sales,
  total_catalog_profit,
  total_web_profit,
  total_returns,
  avg_web_tax,
  sales_volume_category,
  ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_combined_sales DESC) AS sales_rank_within_cc
FROM aggregated
ORDER BY total_combined_sales DESC
LIMIT 100
