SELECT
    d_ws.d_year AS year,
    i.i_category AS category,
    cc.cc_name AS call_center,
    ca_bill.ca_state AS state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    MIN(d_ws.d_date) AS min_sale_date,
    MAX(d_ws.d_date) AS max_sale_date
FROM web_sales ws
JOIN date_dim d_ws
  ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer c_refund
  ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
WHERE d_ws.d_year = 2001
  AND i.i_category = 'Electronics'
  AND cc.cc_name = 'Call Center 1'
  AND c_bill.c_preferred_cust_flag = 'Y'
  AND ca_bill.ca_street_type = 'Drive'
  AND cr.cr_return_amount > 1000
GROUP BY GROUPING SETS (
    (d_ws.d_year, i.i_category, cc.cc_name, ca_bill.ca_state),
    (d_ws.d_year, i.i_category, cc.cc_name),
    (d_ws.d_year, i.i_category),
    (d_ws.d_year),
    ()
)
ORDER BY year, category, call_center, state
LIMIT 100
