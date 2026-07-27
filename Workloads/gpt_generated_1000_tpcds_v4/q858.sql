WITH per_customer AS (
  SELECT
    c.c_customer_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(ws.ws_ext_sales_price - ws.ws_ext_discount_amt) AS web_sales_net
  FROM catalog_returns cr
  JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  WHERE d_cr.d_year = 2001
    AND r.r_reason_desc LIKE '%color%'
    AND ib.ib_lower_bound >= 30000
    AND ca_ref.ca_state = 'CA'
    AND ss.ss_quantity > 0
    AND ws.ws_net_paid > 100
  GROUP BY c.c_customer_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
  ib_lower_bound,
  ib_upper_bound,
  AVG(total_return) AS avg_total_return,
  COUNT(*) AS num_customers
FROM (
  SELECT
    c_customer_sk,
    ib_lower_bound,
    ib_upper_bound,
    COALESCE(catalog_return_amount, 0) + COALESCE(store_return_amount, 0) + COALESCE(web_sales_net, 0) AS total_return
  FROM per_customer
) t
GROUP BY ib_lower_bound, ib_upper_bound
HAVING AVG(total_return) > 5000
ORDER BY avg_total_return DESC
LIMIT 100
