SELECT
    s.s_store_id,
    s.s_city,
    d_store_closed.d_year AS promo_year,
    d_store_closed.d_moy AS promo_month,
    CASE
        WHEN i.i_current_price >= 100 THEN 'high'
        WHEN i.i_current_price >= 50 THEN 'mid'
        ELSE 'low'
    END AS price_tier,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    COUNT(DISTINCT p.p_promo_id) AS num_promotions,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(i.i_wholesale_cost) AS total_wholesale_cost,
    SUM(p.p_cost) / NULLIF(SUM(i.i_wholesale_cost), 0) AS promo_to_wholesale_ratio,
    COUNT(DISTINCT CASE WHEN p.p_discount_active = 'Y' THEN p.p_promo_id END) AS num_active_discounts
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN item i
    ON p.p_item_sk = i.i_item_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_store_closed.d_date_sk
WHERE
    p.p_cost > 0
    AND i.i_current_price IS NOT NULL
    AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_store_closed.d_year,
    d_store_closed.d_moy,
    CASE
        WHEN i.i_current_price >= 100 THEN 'high'
        WHEN i.i_current_price >= 50 THEN 'mid'
        ELSE 'low'
    END
ORDER BY total_promo_cost DESC
LIMIT 100
