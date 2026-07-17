SELECT
    s.s_store_id,
    s.s_store_name,
    c.c_last_name,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    COUNT(*) AS return_count,
    AVG(sr.sr_return_amt) AS avg_return_amount
FROM store_returns sr
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE s.s_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
  AND sr.sr_return_amt > 100
  AND c.c_last_name IN ('Brown', 'Watkins')
GROUP BY s.s_store_id, s.s_store_name, c.c_last_name
ORDER BY total_return_amount DESC
