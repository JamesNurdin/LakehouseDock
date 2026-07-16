SELECT d.d_year,
       s.s_state,
       i.i_category,
       sum(COALESCE(ss.ss_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) AS net_profit,
       sum(COALESCE(ss.ss_net_paid, 0) - COALESCE(sr.sr_return_amt_inc_tax, 0)) AS net_paid,
       count(DISTINCT ss.ss_ticket_number) AS sales_txns,
       count(DISTINCT sr.sr_ticket_number) AS return_txns
FROM store_sales ss
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year = 2000
GROUP BY d.d_year, s.s_state, i.i_category
HAVING sum(COALESCE(ss.ss_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) > 0
ORDER BY net_profit DESC
LIMIT 50
