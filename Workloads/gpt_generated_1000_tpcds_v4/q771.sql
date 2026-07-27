SELECT
    ca_ss.ca_state AS store_state,
    ca_wr_ref.ca_state AS refund_state,
    i.i_category AS item_category,
    r.r_reason_desc,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_loss,
    CASE
        WHEN SUM(ss.ss_net_profit) > SUM(wr.wr_net_loss) THEN 'Profit > Loss'
        ELSE 'Loss >= Profit'
    END AS profit_vs_loss_flag,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders
FROM store_sales ss
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd_ss
  ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
  ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN income_band ib_ss
  ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN household_demographics hd_wr_ref
  ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN income_band ib_wr_ref
  ON hd_wr_ref.hd_income_band_sk = ib_wr_ref.ib_income_band_sk
JOIN customer_address ca_wr_ref
  ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
JOIN household_demographics hd_wr_ret
  ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
JOIN income_band ib_wr_ret
  ON hd_wr_ret.hd_income_band_sk = ib_wr_ret.ib_income_band_sk
JOIN customer_address ca_wr_ret
  ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
GROUP BY
    ca_ss.ca_state,
    ca_wr_ref.ca_state,
    i.i_category,
    r.r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
