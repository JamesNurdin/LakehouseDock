WITH base AS (
  SELECT
    ws.ws_order_number,
    ws.ws_web_site_sk,
    ws.ws_net_paid_inc_ship,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_bill_hdemo_sk,
    ws.ws_bill_addr_sk,
    ws.ws_sold_date_sk,
    cd.cd_gender,
    cd.cd_credit_rating,
    hd.hd_income_band_sk
  FROM web_sales ws
  JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE d_ws.d_year = 2001
    AND cd.cd_education_status = 'College'
    AND hd.hd_income_band_sk BETWEEN 3 AND 5
    AND ws.ws_net_paid_inc_ship > 1000
    AND cd.cd_credit_rating = 'Good'
    AND ws.ws_ext_sales_price IS NOT NULL
),
joined AS (
  SELECT
    b.ws_web_site_sk,
    ws_site.web_name,
    b.cd_gender,
    b.ws_net_paid_inc_ship,
    b.ws_order_number,
    b.ws_item_sk,
    b.ws_bill_customer_sk,
    b.ws_bill_addr_sk,
    d_cr.d_month_seq AS cr_month_seq,
    d_wr.d_month_seq AS wr_month_seq
  FROM base b
  JOIN web_site ws_site
    ON b.ws_web_site_sk = ws_site.web_site_sk
  JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = b.ws_bill_customer_sk
  JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
  JOIN web_returns wr
    ON wr.wr_order_number = b.ws_order_number
   AND wr.wr_item_sk = b.ws_item_sk
  JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
  WHERE d_cr.d_month_seq = 12
    AND d_wr.d_month_seq = 12
    AND EXISTS (
      SELECT 1
      FROM customer_address ca
      WHERE ca.ca_state = 'CA'
        AND ca.ca_address_sk = b.ws_bill_addr_sk
    )
)
SELECT
  ws_web_site_sk,
  web_name,
  cd_gender,
  SUM(ws_net_paid_inc_ship) AS sum_sales,
  COUNT(*) AS order_cnt,
  CASE WHEN SUM(ws_net_paid_inc_ship) > 5000 THEN 'High' ELSE 'Medium' END AS sales_category,
  ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_paid_inc_ship) DESC) AS site_rank
FROM joined
GROUP BY ws_web_site_sk, web_name, cd_gender
HAVING SUM(ws_net_paid_inc_ship) > 2000
ORDER BY sum_sales DESC
LIMIT 100
