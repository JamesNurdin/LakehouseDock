SELECT c.c_customer_id,
       s.s_store_id,
       SUM(ss.ss_ext_sales_price) AS total_sales_amount,
       SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
       SUM(ss.ss_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax) AS net_sales_amount,
       AVG(ss.ss_quantity) AS avg_quantity_per_sale,
       RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax) DESC) AS customer_rank_by_spend
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                         AND sr.sr_store_sk = s.s_store_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
WHERE s.s_market_id = 7
GROUP BY c.c_customer_id, s.s_store_id
ORDER BY net_sales_amount DESC
LIMIT 50
