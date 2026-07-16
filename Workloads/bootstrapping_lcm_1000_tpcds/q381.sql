SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    sm.sm_type AS ship_mode_type,
    p.p_promo_name AS promotion_name,
    p.p_discount_active AS discount_active,
    s.s_city AS store_city,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0)) AS profit_margin,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(CASE WHEN d_ship.d_date BETWEEN d_start.d_date AND d_end.d_date THEN cs.cs_net_paid ELSE 0 END) AS net_paid_during_promo,
    SUM(CASE WHEN d_ship.d_date BETWEEN d_start.d_date AND d_end.d_date THEN 1 ELSE 0 END) AS orders_during_promo
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year >= 2020
  AND sm.sm_type IN ('AIR', 'RAIL', 'TRUCK')
  AND p.p_discount_active = 'Y'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    p.p_promo_name,
    p.p_discount_active,
    s.s_city
ORDER BY total_net_paid DESC
LIMIT 100
