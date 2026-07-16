SELECT
    cp.cp_catalog_page_id,
    cp.cp_description,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_channel_tv,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    d_ship.d_date AS store_closed_date,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_quantity) AS total_quantity,
    MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
    MAX(cs.cs_ship_date_sk) AS max_ship_date_sk
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sold.d_year = 2023
  AND p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_description,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_channel_tv,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    d_start.d_date,
    d_end.d_date,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_ship.d_date
ORDER BY total_net_paid DESC
LIMIT 100
