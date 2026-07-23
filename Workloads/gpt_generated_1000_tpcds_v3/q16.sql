SELECT
    wp.wp_url,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    MIN(ws.ws_net_paid_inc_tax) AS min_net_paid_inc_tax,
    MAX(ws.ws_net_paid_inc_tax) AS max_net_paid_inc_tax,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(wr.wr_return_quantity) AS return_rows
FROM tpcds.web_sales ws
JOIN tpcds.household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
WHERE ws.ws_net_paid_inc_tax > 1000.0
  AND ws.ws_quantity >= 2
  AND ws.ws_list_price > 50.0
  AND hd.hd_dep_count >= 2
  AND hd.hd_vehicle_count >= 1
  AND hd.hd_income_band_sk IN (4, 5, 9)
  AND wp.wp_type = 'Content'
  AND wp.wp_char_count BETWEEN 1000 AND 5000
  AND wr.wr_return_quantity > 0
GROUP BY
    wp.wp_url,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    hd.hd_vehicle_count
ORDER BY total_sales DESC
LIMIT 100
