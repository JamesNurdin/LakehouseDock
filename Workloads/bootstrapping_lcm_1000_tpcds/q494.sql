SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store.d_date AS store_closed_date,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promotions,
    SUM(p.p_cost) AS total_promotion_cost,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(d_ship.d_date) AS earliest_ship_date,
    MAX(d_ship.d_date) AS latest_ship_date
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_store.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store.d_date
ORDER BY total_promotion_cost DESC
LIMIT 100
