SELECT i.i_category,
       i.i_class,
       ca.ca_state,
       SUM(sr.sr_return_amt) AS total_return_amount,
       SUM(sr.sr_return_quantity) AS total_return_qty,
       AVG(sr.sr_return_tax) AS avg_return_tax,
       COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
       RANK() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS category_rank
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE i.i_category IN ('Electronics', 'Furniture', 'Clothing')
  AND ca.ca_state IN ('CA', 'NY', 'TX')
  AND sr.sr_return_amt > 0
GROUP BY i.i_category, i.i_class, ca.ca_state
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 50
