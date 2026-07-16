SELECT
    d_inv.d_year,
    d_inv.d_month_seq,
    d_inv.d_day_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    AVG(wp.wp_char_count) AS avg_char_count,
    DATE_DIFF('day', d_creation.d_date, d_access.d_date) AS days_between_creation_and_access,
    COUNT(*) AS row_count
FROM inventory i
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN web_page wp
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_inv.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND w.w_state = 'CA'
GROUP BY
    d_inv.d_year,
    d_inv.d_month_seq,
    d_inv.d_day_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    d_creation.d_date,
    d_access.d_date
ORDER BY total_qty_on_hand DESC
LIMIT 100
