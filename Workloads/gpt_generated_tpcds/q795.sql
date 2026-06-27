SELECT
    s.s_store_id AS store_id,
    s.s_city AS city,
    s.s_state AS state,
    t.t_shift AS shift,
    COUNT(*) AS total_returns,
    SUM(sr.sr_return_quantity) AS total_quantity,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM store_returns sr
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
GROUP BY s.s_store_id, s.s_city, s.s_state, t.t_shift
HAVING COUNT(*) > 100
ORDER BY total_return_amount DESC
LIMIT 10
