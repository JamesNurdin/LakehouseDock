SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_paid_inc_tax,
    cs.cs_sales_price,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    d_page_start.d_date AS page_start_date,
    d_page_end.d_date AS page_end_date,
    p.p_promo_name,
    p.p_discount_active,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    s.s_store_name,
    s.s_city,
    d_store.d_date AS store_closed_date
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE cs.cs_net_paid > 0
ORDER BY cs.cs_net_paid DESC
LIMIT 100
