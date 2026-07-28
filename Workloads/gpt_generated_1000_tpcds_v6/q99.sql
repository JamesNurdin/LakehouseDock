WITH base AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_addr_sk AS ss_addr_sk,
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_order_number,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
    FROM store_sales ss
    JOIN web_sales ws
      ON ss.ss_item_sk = ws.ws_item_sk
     AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    GROUP BY ss.ss_item_sk,
             ss.ss_sold_date_sk,
             ss.ss_sold_time_sk,
             ss.ss_addr_sk,
             ws.ws_warehouse_sk,
             ws.ws_ship_mode_sk,
             ws.ws_promo_sk,
             ws.ws_bill_addr_sk,
             ws.ws_order_number
)
SELECT
    i.i_category,
    d_day.d_day_name,
    w.w_warehouse_name,
    sm.sm_type AS ship_type,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(b.store_sales_amount) AS total_store_sales,
    SUM(b.web_sales_amount) AS total_web_sales,
    CASE
        WHEN SUM(b.store_sales_amount + b.web_sales_amount) > 100000 THEN 'High'
        WHEN SUM(b.store_sales_amount + b.web_sales_amount) BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_level,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM base b
JOIN item i
  ON i.i_item_sk = b.ss_item_sk
JOIN date_dim d_day
  ON d_day.d_date_sk = b.ss_sold_date_sk
JOIN time_dim t_day
  ON t_day.t_time_sk = b.ss_sold_time_sk
JOIN warehouse w
  ON w.w_warehouse_sk = b.ws_warehouse_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = b.ws_ship_mode_sk
JOIN promotion p
  ON p.p_promo_sk = b.ws_promo_sk
JOIN customer_address ca_store
  ON ca_store.ca_address_sk = b.ss_addr_sk
JOIN customer_address ca_bill
  ON ca_bill.ca_address_sk = b.ws_bill_addr_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = b.ss_item_sk
 AND cr.cr_returned_date_sk = b.ss_sold_date_sk
LEFT JOIN reason r_cr
  ON r_cr.r_reason_sk = cr.cr_reason_sk
LEFT JOIN household_demographics hd_cr
  ON hd_cr.hd_demo_sk = cr.cr_refunded_hdemo_sk
LEFT JOIN income_band ib
  ON ib.ib_income_band_sk = hd_cr.hd_income_band_sk
LEFT JOIN warehouse w_ret
  ON w_ret.w_warehouse_sk = cr.cr_warehouse_sk
LEFT JOIN ship_mode sm_ret
  ON sm_ret.sm_ship_mode_sk = cr.cr_ship_mode_sk
LEFT JOIN date_dim d_ret
  ON d_ret.d_date_sk = cr.cr_returned_date_sk
LEFT JOIN time_dim t_ret
  ON t_ret.t_time_sk = cr.cr_returned_time_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = b.ss_item_sk
 AND wr.wr_returned_date_sk = b.ss_sold_date_sk
 AND wr.wr_order_number = b.ws_order_number
LEFT JOIN reason r_wr
  ON r_wr.r_reason_sk = wr.wr_reason_sk
LEFT JOIN date_dim d_ret_wr
  ON d_ret_wr.d_date_sk = wr.wr_returned_date_sk
LEFT JOIN time_dim t_ret_wr
  ON t_ret_wr.t_time_sk = wr.wr_returned_time_sk
GROUP BY
    i.i_category,
    d_day.d_day_name,
    w.w_warehouse_name,
    sm.sm_type,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_store_sales + total_web_sales DESC
LIMIT 100
