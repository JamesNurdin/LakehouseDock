SELECT
    d_inv.d_year,
    CASE WHEN d_inv.d_moy <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    cc.cc_division_name,
    s.s_division_name,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
    COUNT(DISTINCT CASE WHEN d_wp_access.d_year = d_inv.d_year THEN wp.wp_web_page_id END) AS pages_accessed_same_year,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    (AVG(cc.cc_tax_percentage) - AVG(s.s_tax_percentage)) AS tax_diff,
    SUM(CASE WHEN i.inv_quantity_on_hand > 0 THEN i.inv_quantity_on_hand ELSE 0 END) AS positive_quantity,
    AVG(date_diff('day', d_cc_open.d_date, d_inv.d_date)) AS avg_days_since_center_open,
    AVG(date_diff('day', d_inv.d_date, d_wp_access.d_date)) AS avg_days_to_page_access,
    COUNT(*) AS row_count
FROM inventory i
JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_inv.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_inv.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_inv.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_inv.d_year BETWEEN 2020 AND 2023
  AND s.s_state = 'CA'
  AND cc.cc_market_manager IS NOT NULL
GROUP BY
    d_inv.d_year,
    CASE WHEN d_inv.d_moy <= 6 THEN 'H1' ELSE 'H2' END,
    cc.cc_division_name,
    s.s_division_name
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY total_quantity DESC
LIMIT 20
