WITH
  sales_agg AS (
    SELECT
      ws.ws_sold_date_sk AS sold_date_sk,
      ws.ws_bill_customer_sk AS cust_sk,
      ws.ws_bill_hdemo_sk AS hdemo_sk,
      ws.ws_ext_sales_price AS ext_sales_price,
      ws.ws_net_profit AS net_profit,
      ws.ws_quantity AS quantity,
      ws.ws_item_sk AS item_sk,
      ws.ws_order_number AS order_number
    FROM web_sales ws
  ),
  returns_agg AS (
    SELECT
      wr.wr_returned_date_sk AS returned_date_sk,
      wr.wr_refunded_customer_sk AS cust_sk,
      wr.wr_refunded_hdemo_sk AS hdemo_sk,
      wr.wr_return_amt AS return_amt,
      wr.wr_net_loss AS net_loss,
      wr.wr_order_number AS order_number
    FROM web_returns wr
  )
SELECT
  d.d_year,
  d.d_month_seq,
  cc.cc_state,
  s.s_state,
  hd.hd_income_band_sk,
  COUNT(DISTINCT sa.cust_sk) AS distinct_customers,
  SUM(sa.ext_sales_price) AS total_sales,
  SUM(sa.net_profit) AS total_profit,
  COALESCE(SUM(ra.net_loss), 0) AS total_return_loss,
  SUM(sa.net_profit) - COALESCE(SUM(ra.net_loss), 0) AS net_profit_after_returns,
  SUM(ra.return_amt) AS total_return_amount,
  AVG(CASE WHEN hd.hd_vehicle_count IS NOT NULL THEN hd.hd_vehicle_count END) AS avg_vehicle_count
FROM sales_agg sa
JOIN date_dim d
  ON sa.sold_date_sk = d.d_date_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN household_demographics hd
  ON sa.hdemo_sk = hd.hd_demo_sk
LEFT JOIN returns_agg ra
  ON sa.order_number = ra.order_number
WHERE d.d_year = 2001
  AND cc.cc_class = 'large'
  AND s.s_state = 'CA'
GROUP BY
  d.d_year,
  d.d_month_seq,
  cc.cc_state,
  s.s_state,
  hd.hd_income_band_sk
ORDER BY
  d.d_year,
  d.d_month_seq,
  total_sales DESC
LIMIT 100
