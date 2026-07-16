SELECT
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_state,
    ws.web_state,
    p.p_promo_id,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(s.s_floor_space) AS avg_floor_space,
    SUM(CASE WHEN d.d_dow IN (1, 7) THEN wr.wr_return_amt ELSE 0 END) AS weekend_return_amount
FROM date_dim d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    s.s_state,
    ws.web_state,
    p.p_promo_id
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
