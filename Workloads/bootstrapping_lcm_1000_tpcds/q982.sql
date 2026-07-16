SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_month,
    wp.wp_url,
    wp.wp_type,
    i.inv_item_sk,
    i.inv_quantity_on_hand,
    d_inv.d_date AS inventory_date,
    d_c_sales.d_date AS first_sales_date,
    d_c_shipto.d_date AS first_shipto_date,
    s.s_store_name,
    s.s_state,
    d_store.d_date AS store_closed_date,
    d_wp_creation.d_date AS page_creation_date,
    d_wp_access.d_date AS page_access_date,
    DATE_DIFF('day', d_c_sales.d_date, d_wp_access.d_date) AS days_between_sales_and_page_access,
    DATE_DIFF('day', d_inv.d_date, d_wp_creation.d_date) AS days_between_inventory_and_page_creation
FROM customer c
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_c_sales
    ON c.c_first_sales_date_sk = d_c_sales.d_date_sk
JOIN date_dim d_c_shipto
    ON c.c_first_shipto_date_sk = d_c_shipto.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_c_sales.d_date_sk
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_c_shipto.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
ORDER BY days_between_sales_and_page_access ASC
LIMIT 100
