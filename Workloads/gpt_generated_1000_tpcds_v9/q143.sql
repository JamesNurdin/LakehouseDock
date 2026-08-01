SELECT
    s.s_store_id AS store_id,
    d.d_date AS sales_date,
    d.d_year,
    d.d_month_seq,
    cp.cp_department,
    t.t_meal_time,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_sales_price) AS avg_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
    MAX(ss.ss_ext_sales_price) AS max_sale,
    MIN(ss.ss_ext_sales_price) AS min_sale,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
    (SELECT COUNT(*) FROM inventory inv2 WHERE inv2.inv_date_sk = d.d_date_sk) AS inventory_records_for_date
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND d.d_month_seq BETWEEN 1200 AND 1300
    AND s.s_state = 'CA'
    AND cp.cp_type = 'quarterly'
    AND (inv.inv_quantity_on_hand > 500 OR inv.inv_quantity_on_hand IS NULL)
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    s.s_store_id,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    cp.cp_department,
    t.t_meal_time,
    d.d_date_sk
ORDER BY
    total_sales DESC,
    s.s_store_id
LIMIT 100
