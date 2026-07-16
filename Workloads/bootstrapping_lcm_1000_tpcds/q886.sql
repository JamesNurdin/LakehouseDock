SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_end.d_date AS catalog_end_date,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_sold.d_year,
    d_ship.d_year,
    d_cp_start.d_date,
    d_cp_end.d_date,
    d_promo_start.d_date,
    d_promo_end.d_date
ORDER BY total_net_paid DESC
LIMIT 100
