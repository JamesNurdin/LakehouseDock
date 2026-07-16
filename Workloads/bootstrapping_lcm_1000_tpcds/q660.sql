SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    d_sold.d_date AS sold_date,
    d_sold.d_year,
    d_sold.d_quarter_name,
    t.t_time,
    t.t_meal_time,
    p.p_promo_name,
    p.p_channel_tv,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    d_ship.d_date AS ship_date,
    DATE_DIFF('day', d_sold.d_date, d_ship.d_date) AS days_to_ship,
    s.s_store_name,
    s.s_market_manager,
    s.s_state,
    (cs.cs_ext_sales_price - cs.cs_ext_discount_amt - cs.cs_ext_tax) AS net_revenue,
    CASE
        WHEN p.p_discount_active = 'Y' THEN (cs.cs_ext_sales_price - cs.cs_ext_discount_amt - cs.cs_ext_tax) * 0.9
        ELSE (cs.cs_ext_sales_price - cs.cs_ext_discount_amt - cs.cs_ext_tax)
    END AS adjusted_revenue,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank_in_store
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE cs.cs_net_paid > 0
  AND d_sold.d_year = 2021
  AND p.p_channel_tv = 'Y'
ORDER BY profit_rank_in_store, cs.cs_order_number
LIMIT 100
