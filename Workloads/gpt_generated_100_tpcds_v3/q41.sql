SELECT
  ca_sales.ca_state AS state,
  ib.ib_lower_bound AS income_lower,
  ib.ib_upper_bound AS income_upper,
  i_sales.i_category AS category,
  r_sr.r_reason_desc AS store_return_reason,
  r_wr.r_reason_desc AS web_return_reason,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_quantity) AS total_units_sold,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(wr.wr_net_loss) AS total_web_return_loss,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
  COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_returns,
  COUNT(DISTINCT wr.wr_order_number) AS distinct_web_returns
FROM store_sales ss
JOIN item i_sales
  ON ss.ss_item_sk = i_sales.i_item_sk
JOIN customer_demographics cd_sales
  ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN household_demographics hd_sales
  ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN customer_address ca_sales
  ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i_sales.i_item_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN income_band ib
  ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
  ca_sales.ca_state,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  i_sales.i_category,
  r_sr.r_reason_desc,
  r_wr.r_reason_desc
ORDER BY total_store_return_loss DESC
LIMIT 100
