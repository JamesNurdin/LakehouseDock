WITH base_date AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    cc.cc_name AS call_center_name,
    w_cat.w_county AS warehouse_county,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    (SELECT MAX(d_date) FROM date_dim) AS max_date
FROM base_date d_ret
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
  ON sr.sr_return_time_sk = t_ret.t_time_sk
JOIN customer c_ret
  ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_cat
  ON cr.cr_returned_date_sk = d_cat.d_date_sk
JOIN time_dim t_cat
  ON cr.cr_returned_time_sk = t_cat.t_time_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w_cat
  ON cr.cr_warehouse_sk = w_cat.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN date_dim d_sales
  ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
  ON ws.ws_sold_time_sk = t_sales.t_time_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w_sales
  ON ws.ws_warehouse_sk = w_sales.w_warehouse_sk
JOIN customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
WHERE w_cat.w_zip = '74136'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_returned_date_sk = cr.cr_returned_date_sk
    )
GROUP BY
    cc.cc_name,
    w_cat.w_county
ORDER BY
    total_return_amount DESC
LIMIT 100
