WITH
    d_sold AS (
        SELECT *
        FROM date_dim
    ),
    d_ship AS (
        SELECT *
        FROM date_dim
    ),
    d_promo_start AS (
        SELECT *
        FROM date_dim
    ),
    d_promo_end AS (
        SELECT *
        FROM date_dim
    ),
    d_wp_create AS (
        SELECT *
        FROM date_dim
    )
SELECT
    c_bill.c_customer_id,
    ca_bill.ca_state,
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit
FROM catalog_sales cs
JOIN d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN inventory i ON i.inv_item_sk = cs.cs_item_sk AND i.inv_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp ON wp.wp_customer_sk = c_bill.c_customer_sk
JOIN d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY
    c_bill.c_customer_id,
    ca_bill.ca_state,
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
