SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    p.p_promo_name AS promo_name,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    SUM(cs.cs_wholesale_cost) AS total_wholesale_cost
FROM catalog_sales cs
JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
JOIN date_dim d_sold
    ON d_sold.d_date_sk = cs.cs_sold_date_sk
JOIN date_dim d_ship
    ON d_ship.d_date_sk = cs.cs_ship_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_closed
    ON d_cc_closed.d_date_sk = cc.cc_closed_date_sk
JOIN date_dim d_cc_open
    ON d_cc_open.d_date_sk = cc.cc_open_date_sk
JOIN date_dim d_promo_start
    ON d_promo_start.d_date_sk = p.p_start_date_sk
JOIN date_dim d_promo_end
    ON d_promo_end.d_date_sk = p.p_end_date_sk
WHERE
    cc.cc_state = 'CA'
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND d_sold.d_year BETWEEN 2000 AND 2002
    AND d_ship.d_year = d_sold.d_year
    AND d_promo_start.d_date <= d_sold.d_date
    AND d_promo_end.d_date >= d_sold.d_date
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
