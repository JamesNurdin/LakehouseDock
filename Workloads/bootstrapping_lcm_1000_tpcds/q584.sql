SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_tax_percentage AS store_tax_percentage,
    c.cc_call_center_id,
    c.cc_name AS call_center_name,
    c.cc_market_manager,
    c.cc_tax_percentage AS call_center_tax_percentage,
    cc_open.d_year AS call_center_open_year,
    cc_closed.d_year AS call_center_closed_year,
    d_inv.d_year AS inventory_year,
    d_inv.d_date AS inventory_date,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
    AVG(c.cc_tax_percentage) AS avg_call_center_tax_percentage,
    COUNT(DISTINCT wp.wp_web_page_id) AS total_web_pages_created,
    COUNT(DISTINCT CASE WHEN wp.wp_access_date_sk = d_inv.d_date_sk THEN wp.wp_web_page_id END) AS web_pages_accessed_on_inventory_date,
    MIN(d_inv.d_date) AS earliest_inventory_date,
    MAX(d_inv.d_date) AS latest_inventory_date
FROM inventory i
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_inv.d_date_sk
JOIN call_center c
    ON c.cc_closed_date_sk = d_inv.d_date_sk
JOIN date_dim cc_closed
    ON c.cc_closed_date_sk = cc_closed.d_date_sk
JOIN date_dim cc_open
    ON c.cc_open_date_sk = cc_open.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_inv.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_tax_percentage,
    c.cc_call_center_id,
    c.cc_name,
    c.cc_market_manager,
    c.cc_tax_percentage,
    cc_open.d_year,
    cc_closed.d_year,
    d_inv.d_year,
    d_inv.d_date
ORDER BY total_quantity_on_hand DESC
LIMIT 100
