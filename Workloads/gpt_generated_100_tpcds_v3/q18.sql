/*
  Goal: Rank household demographic segments by total store sales net paid and compare against web sales and return amounts.
*/
WITH demo_agg AS (
  SELECT
    h.hd_demo_sk,
    i.ib_lower_bound,
    i.ib_upper_bound,
    MIN(wp.wp_url) AS example_url,
    SUM(s.ss_net_paid) AS total_store_sales_paid,
    SUM(ws.ws_net_paid) AS total_web_sales_paid,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount
  FROM store_sales s
  JOIN household_demographics h
    ON s.ss_hdemo_sk = h.hd_demo_sk
  JOIN income_band i
    ON h.hd_income_band_sk = i.ib_income_band_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_hdemo_sk = h.hd_demo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_hdemo_sk = h.hd_demo_sk
  LEFT JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = h.hd_demo_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE s.ss_sold_date_sk BETWEEN 2450810 AND 2450820
    AND s.ss_quantity > 1
    AND cr.cr_return_amount > 1000
    AND sr.sr_return_quantity > 0
    AND ws.ws_ext_list_price > 5000
    AND wp.wp_autogen_flag = 'N'
    AND i.ib_lower_bound >= 50000
  GROUP BY h.hd_demo_sk, i.ib_lower_bound, i.ib_upper_bound
)
SELECT
  hd_demo_sk,
  ib_lower_bound,
  ib_upper_bound,
  example_url,
  total_store_sales_paid,
  total_web_sales_paid,
  total_catalog_return_amount,
  total_store_return_amount,
  ROW_NUMBER() OVER (ORDER BY total_store_sales_paid DESC) AS store_sales_rank,
  RANK() OVER (ORDER BY total_web_sales_paid DESC) AS web_sales_rank,
  DENSE_RANK() OVER (ORDER BY (total_catalog_return_amount + total_store_return_amount) DESC) AS total_return_rank
FROM demo_agg
ORDER BY store_sales_rank
LIMIT 100
