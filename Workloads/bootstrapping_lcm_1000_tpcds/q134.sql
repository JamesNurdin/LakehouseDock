SELECT
    s_info.s_store_name,
    s_info.s_city,
    s_info.s_state,
    p.p_promo_name,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    t.t_hour,
    t.t_meal_time,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    s_info.store_closed_date
FROM date_dim d_sold
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
CROSS JOIN (
    SELECT
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sc.d_date AS store_closed_date
    FROM store s
    JOIN date_dim d_sc
        ON s.s_closed_date_sk = d_sc.d_date_sk
) AS s_info
WHERE p.p_discount_active = 'Y'
  AND d_sold.d_year = 2022
GROUP BY
    s_info.s_store_name,
    s_info.s_city,
    s_info.s_state,
    p.p_promo_name,
    d_sold.d_date,
    d_ship.d_date,
    t.t_hour,
    t.t_meal_time,
    d_promo_start.d_date,
    d_promo_end.d_date,
    s_info.store_closed_date
ORDER BY total_net_paid DESC
LIMIT 100
