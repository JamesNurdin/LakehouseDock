SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    ship.d_date AS first_ship_date,
    ship.d_day_name AS ship_day_name,
    sales.d_date AS first_sales_date,
    sales.d_day_name AS sales_day_name,
    review.d_date AS last_review_date,
    review.d_day_name AS review_day_name,
    inv.inv_item_sk,
    inv.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY inv.inv_quantity_on_hand DESC) AS inventory_rank,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    st.s_store_name,
    st.s_city AS store_city,
    st.s_state AS store_state,
    closed.d_date AS store_closed_date,
    closed.d_day_name AS store_closed_day_name
FROM customer c
JOIN date_dim ship
    ON c.c_first_shipto_date_sk = ship.d_date_sk
JOIN date_dim sales
    ON c.c_first_sales_date_sk = sales.d_date_sk
JOIN date_dim review
    ON c.c_last_review_date = review.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = ship.d_date_sk
LEFT JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store st
    ON st.s_closed_date_sk = review.d_date_sk
LEFT JOIN date_dim closed
    ON st.s_closed_date_sk = closed.d_date_sk
WHERE inv.inv_quantity_on_hand IS NOT NULL
ORDER BY c.c_customer_id, inventory_rank
LIMIT 200
