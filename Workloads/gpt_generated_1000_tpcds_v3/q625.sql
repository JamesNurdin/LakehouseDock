SELECT
    d.d_year,
    s.s_state,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    MIN(cr.cr_net_loss) AS min_net_loss,
    MAX(cr.cr_net_loss) AS max_net_loss,
    SUM(p.p_cost) AS total_promo_cost
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
  ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND c.c_preferred_cust_flag = 'Y'
  AND s.s_state = 'CA'
GROUP BY d.d_year, s.s_state
ORDER BY total_return_amount DESC
LIMIT 10
