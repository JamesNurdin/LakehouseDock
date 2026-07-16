SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_catalog_number,
    p.p_promo_name,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    d_ship.d_day_name AS ship_day_name,
    d_page_start.d_date AS page_start_date,
    d_page_end.d_date AS page_end_date,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_count,
    CASE WHEN SUM(cs.cs_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS revenue_category
FROM
    date_dim d_sold
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN date_dim d_page_start ON cp.cp_start_date_sk = d_page_start.d_date_sk
    LEFT JOIN date_dim d_page_end ON cp.cp_end_date_sk = d_page_end.d_date_sk
    LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_catalog_number,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_day_name,
    d_page_start.d_date,
    d_page_end.d_date,
    d_promo_start.d_date,
    d_promo_end.d_date
ORDER BY total_net_paid DESC
LIMIT 100
