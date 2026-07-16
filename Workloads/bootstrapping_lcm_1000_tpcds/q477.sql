SELECT
    d.d_date AS open_date,
    d.d_year,
    d.d_quarter_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_state,
    d_close.d_date AS close_date,
    d_access.d_date AS page_access_date,
    date_diff('day', d.d_date, d_close.d_date) AS site_open_to_close_days,
    date_diff('day', d.d_date, d_access.d_date) AS page_creation_to_access_days,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    AVG(ws.web_tax_percentage) AS avg_tax_percentage,
    MIN(wp.wp_char_count) AS min_char_count,
    MAX(wp.wp_image_count) AS max_image_count
FROM date_dim d
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND ws.web_tax_percentage > 0
GROUP BY
    d.d_date,
    d.d_year,
    d.d_quarter_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_state,
    d_close.d_date,
    d_access.d_date
HAVING SUM(i.inv_quantity_on_hand) > 500
ORDER BY total_inventory DESC
LIMIT 100
