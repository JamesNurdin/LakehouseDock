SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit_after_returns
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
  AND sr.sr_ticket_number = ss.ss_ticket_number
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
GROUP BY d.d_year, d.d_month_seq, i.i_category
ORDER BY d.d_year, d.d_month_seq, i.i_category
