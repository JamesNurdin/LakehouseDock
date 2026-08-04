SELECT
    cp.cp_department,
    sm.sm_carrier,
    d_ret.d_year,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    MIN(cr.cr_refunded_cash) AS min_refunded_cash,
    MAX(cr.cr_refunded_cash) AS max_refunded_cash
FROM catalog_page cp
INNER JOIN catalog_returns cr
    ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
INNER JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
RIGHT OUTER JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
INNER JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
INNER JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
INNER JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_catalog_page_number BETWEEN 5 AND 15
  AND d_ret.d_date = DATE '2001-07-04'
  AND t_ret.t_meal_time = 'lunch'
  AND sm.sm_carrier = 'UPS'
  AND ws.ws_net_profit > 0
  AND ws.ws_quantity >= 20
  AND c.c_email_address LIKE '%@VFAxlnZEvOx.org'
GROUP BY cp.cp_department, sm.sm_carrier, d_ret.d_year
ORDER BY total_sales DESC
LIMIT 100
