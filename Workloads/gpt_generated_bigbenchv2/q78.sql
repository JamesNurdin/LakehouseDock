SELECT
    ss.ss_store_id,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    SUM(ss.ss_quantity * i.i_price) / NULLIF(SUM(ss.ss_quantity), 0) AS avg_price
FROM store_sales ss
JOIN items i
    ON ss.ss_item_id = i.i_item_id
GROUP BY ss.ss_store_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
