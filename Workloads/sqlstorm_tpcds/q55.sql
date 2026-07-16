SELECT
    s.s_state,
    d.d_year,
    i.i_category,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_returns,
    SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit_adjusted
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
    AND ss.ss_store_sk = sr.sr_store_sk
    AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND s.s_state IN ('TX', 'CA', 'NY')
GROUP BY s.s_state, d.d_year, i.i_category
ORDER BY s.s_state, d.d_year, total_sales DESC
LIMIT 100
