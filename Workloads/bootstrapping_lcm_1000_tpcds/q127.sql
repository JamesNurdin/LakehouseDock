SELECT
    dr.d_year,
    dr.d_month_seq,
    s.s_division_name,
    s.s_state,
    p.p_promo_name,
    p.p_discount_active,
    date_diff('day', dr.d_date, de.d_date) AS promo_duration_days,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(p.p_cost) AS total_promo_cost,
    ws.web_state,
    ws.web_gmt_offset
FROM catalog_returns cr
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = dr.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = dr.d_date_sk
JOIN date_dim de
    ON p.p_end_date_sk = de.d_date_sk
WHERE dr.d_year BETWEEN 2000 AND 2005
  AND s.s_state IN ('CA', 'NY', 'TX')
  AND ws.web_state IS NOT NULL
  AND p.p_discount_active = 'Y'
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    s.s_division_name,
    s.s_state,
    p.p_promo_name,
    p.p_discount_active,
    dr.d_date,
    de.d_date,
    ws.web_state,
    ws.web_gmt_offset
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
