SELECT
    d.d_year,
    d.d_quarter_seq,
    (d.d_month_seq % 3) AS month_mod3,
    r.r_reason_desc,
    s.s_city,
    s.s_state,
    w.w_state AS warehouse_state,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_net_loss) AS net_loss,
    SUM(cr.cr_fee) AS total_fee,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    CASE
        WHEN SUM(cr.cr_net_loss) > 50000 THEN 'Very High'
        WHEN SUM(cr.cr_net_loss) > 20000 THEN 'High'
        WHEN SUM(cr.cr_net_loss) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2021
    AND s.s_state IS NOT NULL
    AND w.w_state IS NOT NULL
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    (d.d_month_seq % 3),
    r.r_reason_desc,
    s.s_city,
    s.s_state,
    w.w_state
HAVING COUNT(*) > 10
ORDER BY net_loss DESC
LIMIT 100
