SELECT
    s.s_store_name,
    d_sale.d_year,
    d_sale.d_moy,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sale
  ON ss.ss_sold_date_sk = d_sale.d_date_sk
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE d_sale.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
GROUP BY s.s_store_name, d_sale.d_year, d_sale.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 10
