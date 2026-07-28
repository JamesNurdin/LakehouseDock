WITH
  catalog_data AS (
    SELECT
      w.w_country AS w_country,
      ib.ib_income_band_sk AS ib_income_band_sk,
      d_sold.d_year AS d_year,
      cs.cs_net_paid AS sales_amount,
      cr.cr_return_amount AS return_amount,
      cs.cs_net_profit AS profit,
      cr.cr_net_loss AS return_loss
    FROM catalog_sales cs
    INNER JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN customer cust_bill
      ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    INNER JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN date_dim d_cr_return
      ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    LEFT JOIN ship_mode sm_cr
      ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN warehouse w_cr
      ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN household_demographics hd_cr_refund
      ON cr.cr_refunded_hdemo_sk = hd_cr_refund.hd_demo_sk
    LEFT JOIN customer cust_refund
      ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
    INNER JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  ),
  web_data AS (
    SELECT
      w.w_country AS w_country,
      ib.ib_income_band_sk AS ib_income_band_sk,
      d_ws_sold.d_year AS d_year,
      ws.ws_net_paid AS sales_amount,
      wr.wr_return_amt AS return_amount,
      ws.ws_net_profit AS profit,
      wr.wr_net_loss AS return_loss
    FROM web_sales ws
    INNER JOIN date_dim d_ws_sold
      ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    INNER JOIN date_dim d_ws_ship
      ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    INNER JOIN customer ws_cust_bill
      ON ws.ws_bill_customer_sk = ws_cust_bill.c_customer_sk
    INNER JOIN household_demographics hd_ws_bill
      ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    INNER JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    INNER JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN date_dim d_wr_return
      ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    LEFT JOIN household_demographics hd_wr_refund
      ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
    LEFT JOIN customer cust_wr_refund
      ON wr.wr_refunded_customer_sk = cust_wr_refund.c_customer_sk
    INNER JOIN income_band ib
      ON hd_ws_bill.hd_income_band_sk = ib.ib_income_band_sk
  )
SELECT
  agg.w_country AS country,
  agg.ib_income_band_sk AS income_band,
  agg.d_year AS year,
  SUM(agg.sales_amount) AS total_sales,
  SUM(COALESCE(agg.return_amount, 0)) AS total_returns,
  SUM(agg.profit) - SUM(COALESCE(agg.return_loss, 0)) AS net_profit
FROM (
  SELECT * FROM catalog_data
  UNION ALL
  SELECT * FROM web_data
) agg
GROUP BY agg.w_country, agg.ib_income_band_sk, agg.d_year
ORDER BY total_sales DESC
LIMIT 100
