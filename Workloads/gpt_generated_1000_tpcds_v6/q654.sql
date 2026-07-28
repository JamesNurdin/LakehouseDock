/* Goal: Calculate yearly sales and returns by item category and customer state for a specific quarter, brand, business hours, high‑quantity sales, defective returns, and high income bands. Demonstrates outer joins and a scalar subquery for overall catalog discount. */
WITH overall_avg AS (
    SELECT AVG(cs2.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs2
)
SELECT
    d_ss.d_year,
    i.i_category,
    ca.ca_state,
    SUM(ss.ss_net_paid)                         AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number)         AS order_count,
    AVG(cs.cs_ext_discount_amt)                 AS avg_catalog_discount,
    SUM(sr.sr_return_amt)                       AS total_store_returns,
    SUM(wr.wr_net_loss)                         AS total_web_loss,
    MAX(ib.ib_upper_bound)                      AS max_income_upper_bound,
    (SELECT avg_discount FROM overall_avg)      AS overall_avg_catalog_discount
FROM store_sales ss
JOIN date_dim d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss
  ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs_sold
  ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN time_dim t_cs
  ON cs.cs_sold_time_sk = t_cs.t_time_sk
LEFT JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c_wr_refund
  ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
JOIN customer_demographics cd_wr_refund
  ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
JOIN household_demographics hd_wr_refund
  ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
JOIN customer_address ca_wr_refund
  ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
WHERE d_ss.d_quarter_name = '1902Q4'
  AND i.i_brand = 'BrandA'
  AND t_ss.t_hour BETWEEN 9 AND 17
  AND ss.ss_quantity > 5
  AND r.r_reason_desc = 'Defective'
  AND (ib.ib_upper_bound >= 50000 OR ib.ib_upper_bound IS NULL)
GROUP BY d_ss.d_year, i.i_category, ca.ca_state
ORDER BY total_sales DESC
LIMIT 100
