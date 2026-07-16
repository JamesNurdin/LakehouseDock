SELECT
    s.s_store_id,
    s.s_state,
    p.p_promo_name,
    p.p_discount_active,
    sold.d_year AS sold_year,
    sold.d_month_seq AS sold_month_seq,
    ship.d_year AS ship_year,
    ship.d_month_seq AS ship_month_seq,
    COUNT(*) AS num_sales,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    SUM(cs.cs_quantity) AS total_quantity,
    MIN(p.p_cost) AS min_promo_cost,
    MAX(p.p_cost) AS max_promo_cost,
    p_start.d_date AS promo_start_date,
    p_end.d_date AS promo_end_date
FROM catalog_sales cs
JOIN date_dim sold ON cs.cs_sold_date_sk = sold.d_date_sk
JOIN date_dim ship ON cs.cs_ship_date_sk = ship.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim p_start ON p.p_start_date_sk = p_start.d_date_sk
JOIN date_dim p_end ON p.p_end_date_sk = p_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = sold.d_date_sk
WHERE cs.cs_net_paid > 0
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    s.s_state,
    p.p_promo_name,
    p.p_discount_active,
    sold.d_year,
    sold.d_month_seq,
    ship.d_year,
    ship.d_month_seq,
    p_start.d_date,
    p_end.d_date
ORDER BY total_net_paid DESC
LIMIT 100
