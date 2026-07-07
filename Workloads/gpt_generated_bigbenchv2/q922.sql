SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    SUM(ss.ss_quantity * i.i_comp_price) AS total_competitive_revenue,
    ROUND(SUM(ss.ss_quantity * i.i_price) / NULLIF(SUM(ss.ss_quantity), 0), 2) AS avg_price_per_item
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_name, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
