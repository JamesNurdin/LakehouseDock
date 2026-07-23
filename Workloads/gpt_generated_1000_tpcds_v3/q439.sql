WITH joined_data AS (
   SELECT
     r.r_reason_desc,
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     c.c_customer_sk,
     ca.ca_state,
     ws.ws_net_paid_inc_ship,
     ss.ss_ext_sales_price,
     ws.ws_ext_sales_price,
     ss.ss_net_profit,
     ws.ws_net_profit,
     cr.cr_return_amount,
     cr.cr_return_quantity,
     wr.wr_return_amt,
     wr.wr_return_quantity
   FROM catalog_returns cr
   JOIN customer c
     ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca
     ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store_sales ss
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN web_sales ws
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_site
     ON ws.ws_web_site_sk = web_site.web_site_sk
   LEFT JOIN web_returns wr
     ON wr.wr_order_number = ws.ws_order_number
   WHERE
     r.r_reason_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAALAAAAAAA')
     AND ib.ib_lower_bound >= 30000
     AND ib.ib_upper_bound <= 100000
     AND c.c_birth_year BETWEEN 1950 AND 1975
     AND ca.ca_state = 'CA'
     AND ws.ws_net_paid_inc_ship > 1000
     AND cr.cr_return_quantity > 0
     AND ws.ws_sold_date_sk >= 2450000
     AND web_site.web_city = 'Georgetown'
),
agg_by_reason_income AS (
   SELECT
     r_reason_desc,
     ib_lower_bound,
     ib_upper_bound,
     COUNT(DISTINCT c_customer_sk) AS num_customers,
     SUM(ss_ext_sales_price) AS total_store_sales,
     SUM(ws_ext_sales_price) AS total_web_sales,
     SUM(cr_return_amount + COALESCE(wr_return_amt, 0)) AS total_return_amount,
     AVG(ss_net_profit + ws_net_profit) AS avg_total_net_profit
   FROM joined_data
   GROUP BY
     r_reason_desc,
     ib_lower_bound,
     ib_upper_bound
   HAVING
     SUM(ss_ext_sales_price) + SUM(ws_ext_sales_price) > 50000
     AND SUM(cr_return_amount + COALESCE(wr_return_amt, 0)) > 1000
)
SELECT
  r_reason_desc,
  ib_lower_bound,
  ib_upper_bound,
  num_customers,
  total_store_sales,
  total_web_sales,
  total_return_amount,
  avg_total_net_profit,
  (total_return_amount / NULLIF(total_store_sales + total_web_sales, 0)) AS return_to_sales_ratio
FROM agg_by_reason_income
ORDER BY return_to_sales_ratio DESC
LIMIT 100
