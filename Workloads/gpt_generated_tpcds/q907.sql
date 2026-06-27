SELECT
  st.s_store_name,
  d.d_year,
  d.d_month_seq,
  SUM(ss.ss_ext_sales_price) AS total_sales_amount,
  SUM(ss.ss_quantity) AS total_sales_quantity,
  COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
  COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_quantity,
  SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_after_returns,
  CASE WHEN SUM(ss.ss_quantity) = 0 THEN 0
       ELSE CAST(COALESCE(SUM(sr.sr_return_quantity), 0) AS double) / SUM(ss.ss_quantity)
  END AS return_rate
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store st
  ON ss.ss_store_sk = st.s_store_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
WHERE d.d_year = 2001
GROUP BY st.s_store_name, d.d_year, d.d_month_seq
ORDER BY st.s_store_name, d.d_year, d.d_month_seq
