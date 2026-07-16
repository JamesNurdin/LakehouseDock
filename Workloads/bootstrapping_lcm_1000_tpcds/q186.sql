SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_department,
    date_sold.d_year AS sold_year,
    date_sold.d_quarter_name AS sold_quarter,
    date_ship.d_year AS ship_year,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_city,
    s.s_state,
    COUNT(*) AS total_sales,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
    CASE WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid) ELSE NULL END AS profit_margin,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_sign,
    MIN(date_sold.d_date) AS first_sale_date,
    MAX(date_sold.d_date) AS last_sale_date,
    SUM(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_net_paid END) AS net_paid_qty_gt_5
FROM
    catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim date_sold ON cs.cs_sold_date_sk = date_sold.d_date_sk
    JOIN date_dim date_ship ON cs.cs_ship_date_sk = date_ship.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim promo_start ON p.p_start_date_sk = promo_start.d_date_sk
    JOIN date_dim promo_end ON p.p_end_date_sk = promo_end.d_date_sk
    JOIN date_dim cp_start ON cp.cp_start_date_sk = cp_start.d_date_sk
    JOIN date_dim cp_end ON cp.cp_end_date_sk = cp_end.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = date_sold.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_department,
    date_sold.d_year,
    date_sold.d_quarter_name,
    date_ship.d_year,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_city,
    s.s_state
HAVING
    SUM(cs.cs_net_paid) > 1000
ORDER BY
    total_net_paid DESC
LIMIT 100
