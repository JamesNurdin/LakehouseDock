SELECT
    d.d_year,
    d.d_month_seq,
    CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_month_seq AS VARCHAR), 2, '0')) AS year_month,
    CASE
        WHEN s.s_state = 'CA' THEN 'California'
        ELSE COALESCE(s.s_state, 'Unknown')
    END AS state_group,
    s.s_division_name,
    ws.web_class,
    COUNT(DISTINCT s.s_store_id) AS closed_store_count,
    COUNT(DISTINCT CASE WHEN ws.web_open_date_sk = d.d_date_sk THEN ws.web_site_id END) AS sites_opened,
    COUNT(DISTINCT CASE WHEN ws.web_close_date_sk = d.d_date_sk THEN ws.web_site_id END) AS sites_closed,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(cr.cr_fee) AS total_fees,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) FILTER (WHERE cr.cr_return_amount > 100) AS high_return_transactions
FROM
    date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk OR ws.web_close_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2020 AND 2022
GROUP BY
    d.d_year,
    d.d_month_seq,
    CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_month_seq AS VARCHAR), 2, '0')),
    CASE
        WHEN s.s_state = 'CA' THEN 'California'
        ELSE COALESCE(s.s_state, 'Unknown')
    END,
    s.s_division_name,
    ws.web_class
HAVING
    SUM(cr.cr_return_amount) > 0
ORDER BY
    d.d_year,
    d.d_month_seq,
    s.s_division_name
