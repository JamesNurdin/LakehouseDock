SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_ship.d_date AS ship_date,
    d_ship.d_year,
    i.inv_item_sk,
    i.inv_quantity_on_hand,
    p.p_promo_name,
    p.p_discount_active,
    p.p_cost,
    d_promo_end.d_date AS promo_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_tax_percentage
FROM customer c
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ship.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_promo_end.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND s.s_tax_percentage > 0.05
  AND i.inv_quantity_on_hand > 0
ORDER BY c.c_customer_id
LIMIT 100
