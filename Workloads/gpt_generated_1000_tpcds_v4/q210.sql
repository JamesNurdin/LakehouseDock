/* Goal: Identify the top‑loss‑generating items for the year 2001, ranking them within each brand and enriching the result with customer type, income‑band details and a flag for large web returns. */
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS web_loss,
    (SUM(COALESCE(cr.cr_net_loss, 0)) + SUM(COALESCE(wr.wr_net_loss, 0))) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY (SUM(COALESCE(cr.cr_net_loss, 0)) + SUM(COALESCE(wr.wr_net_loss, 0))) DESC) AS brand_rank,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2 WHERE ib2.ib_lower_bound = ib.ib_lower_bound) AS max_upper_bound_same_lower,
    EXISTS (SELECT 1 FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk AND wr2.wr_return_amt > 100) AS has_large_web_return
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_item_sk = i.i_item_sk
  AND cr.cr_refunded_customer_sk = c.c_customer_sk
  AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_item_sk = i.i_item_sk
  AND wr.wr_refunded_customer_sk = c.c_customer_sk
  AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND hd.hd_buy_potential = '1001-5000'
  AND ib.ib_lower_bound >= 50000
  AND c.c_preferred_cust_flag = 'Y'
  AND w.w_state = 'CA'
  AND cr.cr_return_tax > 10.00
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    d.d_year,
    c.c_preferred_cust_flag,
    ib.ib_lower_bound
ORDER BY total_loss DESC, brand_rank ASC
LIMIT 100
