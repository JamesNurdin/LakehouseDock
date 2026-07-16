SELECT
    s.s_store_id,
    s.s_store_name,
    sm.sm_type,
    p.p_promo_name,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    CASE
        WHEN SUM(cs.cs_net_paid) = 0 THEN 0
        ELSE ROUND(SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid) * 100, 2)
    END AS profit_margin_percent
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sold.d_year = 2020
  AND d_ship.d_year = 2020
  AND d_promo_start.d_year <= d_sold.d_year
  AND d_promo_end.d_year >= d_sold.d_year
GROUP BY
    s.s_store_id,
    s.s_store_name,
    sm.sm_type,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
