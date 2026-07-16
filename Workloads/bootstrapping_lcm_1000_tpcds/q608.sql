SELECT
    d_closed.d_year AS year,
    d_closed.d_month_seq AS month_seq,
    cc.cc_division,
    s.s_division_id,
    COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT wp.wp_web_page_id) AS num_pages_created,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    MAX(cc.cc_gmt_offset) - MIN(s.s_gmt_offset) AS gmt_offset_range,
    AVG(date_diff('day', d_closed.d_date, d_access.d_date)) AS avg_days_to_access,
    CASE
        WHEN SUM(i.inv_quantity_on_hand) > 10000 THEN 'High Stock'
        WHEN SUM(i.inv_quantity_on_hand) BETWEEN 1000 AND 10000 THEN 'Medium Stock'
        ELSE 'Low Stock'
    END AS stock_level
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_closed.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    d_closed.d_year,
    d_closed.d_month_seq,
    cc.cc_division,
    s.s_division_id
HAVING
    COUNT(DISTINCT wp.wp_web_page_id) > 0
ORDER BY total_inventory_qty DESC
LIMIT 100
