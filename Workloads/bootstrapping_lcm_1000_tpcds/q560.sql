SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    p.p_promo_id,
    p.p_discount_active,
    p.p_cost,
    s.s_store_name,
    s.s_state,
    ws.web_name,
    ws.web_state,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN wr.wr_return_amt * p.p_cost ELSE 0 END) AS discount_weighted_return
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND ws.web_state = 'CA'
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    p.p_promo_id,
    p.p_discount_active,
    p.p_cost,
    s.s_store_name,
    s.s_state,
    ws.web_name,
    ws.web_state
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
