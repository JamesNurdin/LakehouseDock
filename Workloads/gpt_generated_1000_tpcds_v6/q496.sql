WITH
  -- Example scalar subquery to get average lower bound of income bands
  avg_income AS (
    SELECT avg(ib_lower_bound) AS avg_lower FROM income_band
  )
SELECT
  d_sold.d_year                              AS sales_year,
  i.i_category                               AS item_category,
  r.r_reason_desc                           AS return_reason,
  SUM(sr.sr_net_loss)                       AS total_store_return_loss,
  SUM(cr.cr_net_loss)                       AS total_catalog_return_loss,
  SUM(wr.wr_net_loss)                       AS total_web_return_loss,
  COUNT(DISTINCT c_bill.c_customer_sk)       AS distinct_bill_customers,
  (SELECT avg_lower FROM avg_income)        AS avg_income_lower_bound
FROM catalog_sales cs
JOIN date_dim d_sold               ON cs.cs_sold_date_sk   = d_sold.d_date_sk
JOIN date_dim d_ship               ON cs.cs_ship_date_sk   = d_ship.d_date_sk
JOIN customer c_bill               ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill      ON cs.cs_bill_addr_sk   = ca_bill.ca_address_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN ship_mode sm                  ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN item i                        ON cs.cs_item_sk        = i.i_item_sk
JOIN catalog_returns cr            ON cr.cr_order_number   = cs.cs_order_number
JOIN date_dim d_cr_return          ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
JOIN customer c_refund             ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer_address ca_refund    ON cr.cr_refunded_addr_sk   = ca_refund.ca_address_sk
JOIN reason r                      ON cr.cr_reason_sk      = r.r_reason_sk
JOIN store_sales ss                ON ss.ss_item_sk        = i.i_item_sk
JOIN date_dim d_ss_sold            ON ss.ss_sold_date_sk   = d_ss_sold.d_date_sk
JOIN customer c_ss                 ON ss.ss_customer_sk    = c_ss.c_customer_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk       = hd_ss.hd_demo_sk
JOIN customer_address ca_ss        ON ss.ss_addr_sk        = ca_ss.ca_address_sk
JOIN store_returns sr              ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_sr_return          ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
JOIN reason r_sr                   ON sr.sr_reason_sk      = r_sr.r_reason_sk
JOIN web_returns wr                ON wr.wr_item_sk        = i.i_item_sk
JOIN date_dim d_wr_return          ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN reason r_wr                   ON wr.wr_reason_sk      = r_wr.r_reason_sk
JOIN web_page wp                   ON wr.wr_web_page_sk    = wp.wp_web_page_sk
JOIN date_dim d_wp_creation        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN web_site ws                   ON ws.web_open_date_sk  = d_sold.d_date_sk
JOIN inventory inv                 ON inv.inv_item_sk = i.i_item_sk
                                    AND inv.inv_date_sk = d_sold.d_date_sk
JOIN household_demographics hd_ws  ON c_bill.c_current_hdemo_sk = hd_ws.hd_demo_sk
JOIN income_band ib                ON hd_ws.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY d_sold.d_year, i.i_category, r.r_reason_desc
ORDER BY total_store_return_loss DESC
LIMIT 100
