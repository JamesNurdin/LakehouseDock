SELECT
    d_ret.d_year AS return_year,
    d_ret.d_quarter_name AS return_quarter,
    w.w_warehouse_name,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_fee) AS total_fees,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
    COUNT(DISTINCT CASE WHEN d_access.d_year = d_ret.d_year THEN wp.wp_web_page_id END) AS distinct_pages_accessed_same_year,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount ELSE 0 END) AS high_qty_return_amount,
    SUM(CASE WHEN cr.cr_return_quantity <= 5 THEN cr.cr_return_amount ELSE 0 END) AS low_qty_return_amount,
    AVG(date_diff('day', d_ret.d_date, d_access.d_date)) AS avg_days_to_access
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE cr.cr_return_amount > 0
  AND w.w_state IS NOT NULL
  AND s.s_state IS NOT NULL
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    w.w_warehouse_name,
    s.s_state
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
