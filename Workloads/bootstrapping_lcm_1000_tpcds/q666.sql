SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    (cs.cs_ext_discount_amt + cs.cs_coupon_amt) AS total_discount,
    cs.cs_net_paid / NULLIF(cs.cs_quantity, 0) AS avg_price_per_item,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC) AS net_paid_rank
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE cs.cs_net_paid > 0
ORDER BY net_paid_rank
LIMIT 100
