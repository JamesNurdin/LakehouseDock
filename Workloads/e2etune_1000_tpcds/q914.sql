SELECT
    p.p_promo_name,
    cp.cp_department,
    d.d_year,
    d.d_month_seq,
    t.t_hour AS return_hour,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    RANK() OVER (PARTITION BY p.p_promo_name, d.d_year, d.d_month_seq ORDER BY SUM(sr.sr_return_amt) DESC) AS dept_rank_by_return
FROM store_returns sr
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
WHERE sr.sr_return_amt > 0
  AND p.p_discount_active = 'Y'
  AND cp.cp_type = 'monthly'
GROUP BY
    p.p_promo_name,
    cp.cp_department,
    d.d_year,
    d.d_month_seq,
    t.t_hour
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
