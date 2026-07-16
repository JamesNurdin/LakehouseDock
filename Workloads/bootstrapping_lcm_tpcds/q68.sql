SELECT
    cc.cc_division_name,
    s.s_state,
    ws.web_market_manager,
    d.d_year,
    d.d_moy AS month_of_year,
    COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
    COUNT(DISTINCT s.s_store_id) AS num_stores,
    COUNT(DISTINCT ws.web_site_id) AS num_websites,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    AVG(ws.web_tax_percentage) AS avg_web_tax,
    CASE WHEN SUM(i.inv_quantity_on_hand) > 5000 THEN 'High' ELSE 'Low' END AS inventory_level
FROM call_center cc
JOIN date_dim d
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
GROUP BY
    cc.cc_division_name,
    s.s_state,
    ws.web_market_manager,
    d.d_year,
    d.d_moy
HAVING SUM(i.inv_quantity_on_hand) > 0
ORDER BY total_inventory DESC
LIMIT 100
