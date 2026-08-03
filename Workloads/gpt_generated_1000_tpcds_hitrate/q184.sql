WITH cs_detail AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_warehouse_sk,
    cs.cs_bill_customer_sk,
    cs.cs_ship_customer_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_ship_cdemo_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_ship_hdemo_sk,
    cc.cc_name,
    cp.cp_department,
    w.w_warehouse_name,
    c_bill.c_first_name AS bill_first_name,
    c_ship.c_first_name AS ship_first_name,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    hd_bill.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    t_sold.t_hour,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
),

wr_detail AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_warehouse_sk,
    ws.ws_web_page_sk,
    ws.ws_bill_customer_sk,
    ws.ws_ship_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_ship_cdemo_sk,
    ws.ws_bill_hdemo_sk,
    ws.ws_ship_hdemo_sk,
    w2.w_warehouse_name,
    wp.wp_url,
    c_bill2.c_first_name AS bill_first_name,
    c_ship2.c_first_name AS ship_first_name,
    cd_bill2.cd_gender AS bill_gender,
    cd_ship2.cd_gender AS ship_gender,
    hd_bill2.hd_income_band_sk,
    ib2.ib_lower_bound,
    ib2.ib_upper_bound,
    t_ws.t_hour,
    CASE WHEN ws.ws_net_profit >= 0 THEN 1 ELSE 0 END AS profit_indicator
  FROM web_sales ws
  JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  JOIN customer c_bill2 ON ws.ws_bill_customer_sk = c_bill2.c_customer_sk
  JOIN customer c_ship2 ON ws.ws_ship_customer_sk = c_ship2.c_customer_sk
  JOIN customer_demographics cd_bill2 ON ws.ws_bill_cdemo_sk = cd_bill2.cd_demo_sk
  JOIN customer_demographics cd_ship2 ON ws.ws_ship_cdemo_sk = cd_ship2.cd_demo_sk
  JOIN household_demographics hd_bill2 ON ws.ws_bill_hdemo_sk = hd_bill2.hd_demo_sk
  JOIN household_demographics hd_ship2 ON ws.ws_ship_hdemo_sk = hd_ship2.hd_demo_sk
  JOIN income_band ib2 ON hd_bill2.hd_income_band_sk = ib2.ib_income_band_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
),

returns_combined AS (
  SELECT
    sr.sr_customer_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    t_ret.t_hour AS return_hour,
    r.r_reason_desc,
    CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS amount_category
  FROM store_returns sr
  JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),

web_returns_detail AS (
  SELECT
    wr.wr_refunded_customer_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    t_wr.t_hour AS return_hour,
    r2.r_reason_desc,
    CASE WHEN wr.wr_return_amt > 50 THEN 'Significant' ELSE 'Minor' END AS amt_category
  FROM web_returns wr
  JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
)

SELECT
  cust.c_customer_id,
  cust.c_first_name,
  cust.c_last_name,
  SUM(cs_detail.cs_net_profit) AS total_catalog_profit,
  SUM(wr_detail.ws_net_profit) AS total_web_profit,
  COUNT(DISTINCT cs_detail.cs_order_number) AS catalog_orders,
  COUNT(DISTINCT wr_detail.ws_order_number) AS web_orders
FROM (
    SELECT cs_bill_customer_sk AS cust_sk FROM cs_detail
    INTERSECT
    SELECT sr_customer_sk FROM returns_combined
) intersect_cust
JOIN customer cust ON cust.c_customer_sk = intersect_cust.cust_sk
LEFT JOIN cs_detail ON cs_detail.cs_bill_customer_sk = cust.c_customer_sk
LEFT JOIN wr_detail ON wr_detail.ws_bill_customer_sk = cust.c_customer_sk
GROUP BY cust.c_customer_id, cust.c_first_name, cust.c_last_name
ORDER BY total_catalog_profit DESC
LIMIT 100
