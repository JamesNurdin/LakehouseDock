SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_ship.d_date AS ship_date,
    d_sales.d_year AS sales_year,
    i.inv_item_sk,
    i.inv_quantity_on_hand,
    i.inv_warehouse_sk,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_store.d_date AS store_closed_date,
    d_promo_end.d_date AS promo_end_date,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY i.inv_quantity_on_hand DESC) AS inventory_rank
FROM customer c
JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN inventory i ON i.inv_date_sk = d_ship.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_ship.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
ORDER BY inventory_rank, i.inv_quantity_on_hand DESC
LIMIT 100
