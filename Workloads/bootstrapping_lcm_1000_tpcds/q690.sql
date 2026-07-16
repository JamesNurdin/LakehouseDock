SELECT
    (d.d_year * 100 + d.d_month_seq) AS year_month,
    s.s_state,
    wp.wp_type,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    (SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_amount), 0)) AS loss_to_amount_ratio,
    CASE
        WHEN SUM(cr.cr_net_loss) > 50000 THEN 'VERY HIGH'
        WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH'
        WHEN SUM(cr.cr_net_loss) > 1000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
  AND wp.wp_type IS NOT NULL
GROUP BY (d.d_year * 100 + d.d_month_seq), s.s_state, wp.wp_type
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
