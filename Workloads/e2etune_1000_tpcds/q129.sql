SELECT
  cd.cd_gender,
  cd.cd_marital_status,
  hd.hd_vehicle_count,
  wp.wp_type,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  SUM(cs.cs_net_profit) AS total_profit,
  COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
  COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss
FROM catalog_sales cs
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_returns wr
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
  AND cd.cd_gender = 'F'
  AND hd.hd_vehicle_count >= 2
GROUP BY cd.cd_gender, cd.cd_marital_status, hd.hd_vehicle_count, wp.wp_type
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 50
