WITH aggregated AS (
  SELECT
    cc.cc_call_center_id AS cc_id,
    d.d_year AS year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(wr.wr_return_amt) AS total_web_return,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT ss.ss_customer_sk) AS num_customers
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_returned_time_sk = t.t_time_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd_cr
    ON cr.cr_refunded_cdemo_sk = cd_cr.cd_demo_sk
  JOIN household_demographics hd_cr
    ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
  JOIN customer_demographics cd_wr
    ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
  JOIN household_demographics hd_wr
    ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND cc.cc_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND cd_ss.cd_gender = 'M'
    AND hd_ss.hd_income_band_sk = 5
  GROUP BY cc.cc_call_center_id, d.d_year
)
SELECT
  cc_id,
  year,
  total_sales,
  total_profit,
  total_inventory_qty,
  (SELECT AVG(total_sales) FROM aggregated) AS avg_sales_overall
FROM aggregated
WHERE total_sales > (SELECT AVG(total_sales) FROM aggregated) * 0.8
ORDER BY total_sales DESC
LIMIT 100
