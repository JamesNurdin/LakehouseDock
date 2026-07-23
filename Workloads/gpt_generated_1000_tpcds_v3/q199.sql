SELECT
    dd_sales.d_year AS year,
    s.s_store_name AS store_name,
    i.i_category AS item_category,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_net_loss,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_net_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_net_loss,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS total_sales_net_profit,
    SUM(COALESCE(ss.ss_quantity, 0)) AS total_sales_quantity,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper_bound
FROM store_sales ss
JOIN date_dim dd_sales
    ON ss.ss_sold_date_sk = dd_sales.d_date_sk
JOIN time_dim td_sales
    ON ss.ss_sold_time_sk = td_sales.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd_sales
    ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN income_band ib
    ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_sales
    ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim dd_closed
    ON s.s_closed_date_sk = dd_closed.d_date_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_store_sk = s.s_store_sk
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim dd_sret
    ON sr.sr_returned_date_sk = dd_sret.d_date_sk
JOIN time_dim td_sret
    ON sr.sr_return_time_sk = td_sret.t_time_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN item i_sr
    ON sr.sr_item_sk = i_sr.i_item_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim dd_cr
    ON cr.cr_returned_date_sk = dd_cr.d_date_sk
JOIN time_dim td_cr
    ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN household_demographics hd_cr_ref
    ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
JOIN customer_address ca_cr_ref
    ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk
JOIN household_demographics hd_cr_ret
    ON cr.cr_returning_hdemo_sk = hd_cr_ret.hd_demo_sk
JOIN customer_address ca_cr_ret
    ON cr.cr_returning_addr_sk = ca_cr_ret.ca_address_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim dd_wr
    ON wr.wr_returned_date_sk = dd_wr.d_date_sk
JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN household_demographics hd_wr_ref
    ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN customer_address ca_wr_ref
    ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
JOIN household_demographics hd_wr_ret
    ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
JOIN customer_address ca_wr_ret
    ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_ticket_number = ss.ss_ticket_number
      AND sr2.sr_net_loss > 0
)
  AND ib.ib_lower_bound >= 50000
GROUP BY
    dd_sales.d_year,
    s.s_store_name,
    i.i_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    total_catalog_net_loss DESC,
    year ASC
LIMIT 100
