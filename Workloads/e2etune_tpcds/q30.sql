WITH sales AS (
  SELECT
    i.i_category,
    cd.cd_gender,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_country = 'ETHIOPIA'
    AND ca.ca_country = 'USA'
    AND ss.ss_sold_date_sk BETWEEN 2452000 AND 2453000
  GROUP BY i.i_category, cd.cd_gender
),
returns AS (
  SELECT
    i.i_category,
    cd.cd_gender,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_country = 'ETHIOPIA'
    AND ca.ca_country = 'USA'
    AND sr.sr_returned_date_sk BETWEEN 2452000 AND 2453000
  GROUP BY i.i_category, cd.cd_gender
)
SELECT
  s.i_category,
  s.cd_gender,
  s.total_profit,
  COALESCE(r.total_return_amt, 0) AS total_return_amt,
  s.total_profit - COALESCE(r.total_return_amt, 0) AS net_profit_adj,
  s.total_sales,
  CASE WHEN s.total_sales > 0 THEN (COALESCE(r.total_return_amt, 0) / s.total_sales) ELSE 0 END AS return_rate,
  RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.total_return_amt, 0)) DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
  ON s.i_category = r.i_category
  AND s.cd_gender = r.cd_gender
ORDER BY net_profit_adj DESC
LIMIT 10
