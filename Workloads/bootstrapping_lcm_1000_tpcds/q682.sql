SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_paid - cs.cs_ext_discount_amt AS net_after_discount,
    cd_gd.cd_marital_status,
    cd_ship.cd_gender AS ship_demo_gender,
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    d_start.d_year AS promo_start_year,
    d_end.d_year AS promo_end_year,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY d_sold.d_date) AS cum_sales_by_customer,
    ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_net_paid DESC) AS rn
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_gd
    ON cs.cs_bill_cdemo_sk = cd_gd.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE cs.cs_net_paid > 0
ORDER BY net_after_discount DESC
LIMIT 100
