SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_city AS shipping_city,
    COALESCE(s.s_store_name, 'N/A') AS store_name,
    CASE WHEN s.s_store_sk IS NULL THEN 'Open' ELSE 'Closed' END AS store_status,
    wp.wp_url,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    CASE
        WHEN SUM(cs.cs_ext_list_price) = 0 THEN NULL
        ELSE SUM(cs.cs_net_paid) / SUM(cs.cs_ext_list_price)
    END AS paid_to_list_ratio
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
   AND wp.wp_access_date_sk = d_ship.d_date_sk
WHERE cs.cs_quantity > 0
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    ca_bill.ca_city,
    ca_ship.ca_city,
    s.s_store_name,
    s.s_store_sk,
    wp.wp_url,
    wp.wp_type
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
