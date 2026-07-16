SELECT
    d_inv.d_year,
    d_inv.d_quarter_name,
    s.s_state,
    s.s_city,
    ws.web_name,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
    AVG(s.s_gmt_offset) AS avg_gmt_offset,
    SUM(CASE WHEN d_access.d_dow IN (6,7) THEN i.inv_quantity_on_hand ELSE 0 END) AS weekend_quantity,
    DATE_DIFF('day', MIN(d_inv.d_date), MAX(d_site_close.d_date)) AS site_lifespan_days,
    MIN(d_inv.d_date) AS earliest_inventory_date,
    MAX(d_site_close.d_date) AS latest_site_close_date
FROM inventory i
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_inv.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_inv.d_date_sk
JOIN date_dim d_site_close
    ON ws.web_close_date_sk = d_site_close.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_inv.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_inv.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    d_inv.d_year,
    d_inv.d_quarter_name,
    s.s_state,
    s.s_city,
    ws.web_name
ORDER BY
    d_inv.d_year,
    d_inv.d_quarter_name,
    s.s_state,
    s.s_city
LIMIT 100
