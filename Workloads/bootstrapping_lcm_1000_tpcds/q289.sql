SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN true ELSE false END AS promo_active,
    CASE
        WHEN sm.sm_type = 'AIR' THEN 'Air'
        WHEN sm.sm_type = 'TRUCK' THEN 'Truck'
        ELSE 'Other'
    END AS ship_mode_group,
    ds.d_year,
    ds.d_month_seq,
    (ds.d_year * 100 + ds.d_month_seq) AS year_month_key,
    dp_start.d_date AS promo_start_date,
    dp_end.d_date AS promo_end_date,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS discount_ratio,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) AS profit_margin,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON-POSITIVE'
    END AS profit_sign
FROM catalog_sales cs
JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dship ON cs.cs_ship_date_sk = dship.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim dp_start ON p.p_start_date_sk = dp_start.d_date_sk
JOIN date_dim dp_end ON p.p_end_date_sk = dp_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = dp_end.d_date_sk
WHERE ds.d_year BETWEEN 1999 AND 2002
  AND p.p_discount_active = 'Y'
  AND sm.sm_type IN ('AIR', 'TRUCK')
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN true ELSE false END,
    CASE
        WHEN sm.sm_type = 'AIR' THEN 'Air'
        WHEN sm.sm_type = 'TRUCK' THEN 'Truck'
        ELSE 'Other'
    END,
    ds.d_year,
    ds.d_month_seq,
    (ds.d_year * 100 + ds.d_month_seq),
    dp_start.d_date,
    dp_end.d_date
