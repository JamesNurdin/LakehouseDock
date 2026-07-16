SELECT
    d.d_year,
    d.d_month_seq,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    s.s_state,
    ws.web_state,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(p.p_cost) AS total_promo_cost,
    MIN(d.d_date) AS earliest_return_date,
    MAX(d.d_date) AS latest_return_date
FROM catalog_returns AS cr
JOIN date_dim AS d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site AS ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN promotion AS p
    ON p.p_start_date_sk = d.d_date_sk
    AND p.p_end_date_sk = d.d_date_sk
WHERE cr.cr_return_amount > 0
  AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    d.d_month_seq,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END,
    s.s_state,
    ws.web_state,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
ORDER BY total_returns DESC
LIMIT 100
