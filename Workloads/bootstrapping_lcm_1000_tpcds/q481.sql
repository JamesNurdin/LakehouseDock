SELECT
    s.s_store_id,
    s.s_store_name,
    wp.wp_url,
    d_sold.d_year AS sold_year,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_net_profit) AS avg_profit,
    AVG(date_diff('day', d_c_first_sales.d_date, d_sold.d_date)) AS avg_days_from_first_sale_to_sold,
    AVG(date_diff('day', d_c_first_shipto.d_date, d_ship.d_date)) AS avg_days_from_first_shipto_to_ship,
    MIN(d_sold.d_date) AS first_sold_date,
    MAX(d_ship.d_date) AS last_ship_date,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_customers,
    c_ship.c_last_name AS shipping_last_name,
    s.s_floor_space,
    s.s_tax_percentage,
    SUM(cs.cs_ext_tax) AS total_tax,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    AVG(cs.cs_sales_price / NULLIF(cs.cs_list_price, 0)) AS avg_price_ratio
FROM
    catalog_sales cs
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    INNER JOIN date_dim d_c_first_sales
        ON c_bill.c_first_sales_date_sk = d_c_first_sales.d_date_sk
    INNER JOIN date_dim d_c_first_shipto
        ON c_bill.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
    INNER JOIN web_page wp
        ON wp.wp_customer_sk = c_bill.c_customer_sk
    INNER JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    INNER JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    CROSS JOIN store s
    INNER JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE
    d_sold.d_year = 2022
    AND s.s_state = 'CA'
    AND wp.wp_type = 'product'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    wp.wp_url,
    d_sold.d_year,
    c_ship.c_last_name,
    s.s_floor_space,
    s.s_tax_percentage
HAVING
    SUM(cs.cs_net_paid) > 10000
ORDER BY
    total_net_paid DESC
LIMIT 100
