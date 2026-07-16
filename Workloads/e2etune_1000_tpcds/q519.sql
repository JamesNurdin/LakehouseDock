SELECT
    s.s_store_id,
    s.s_state,
    ca.ca_state AS customer_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    (SUM(ss.ss_net_paid) - SUM(COALESCE(wr.wr_return_amt_inc_tax, 0))) AS net_sales_after_returns,
    (SUM(ss.ss_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_profit_after_returns
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   AND wr.wr_returned_date_sk = ss.ss_sold_date_sk
WHERE s.s_state IN ('CA', 'TX', 'NY')
  AND ca.ca_state = 'CA'
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451500
  AND ss.ss_quantity > 0
GROUP BY
    s.s_store_id,
    s.s_state,
    ca.ca_state
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY net_sales_after_returns DESC
LIMIT 50
