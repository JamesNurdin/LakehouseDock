SELECT
    ss.ss_ticket_number,
    ca.ca_address_id,
    concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
    CASE WHEN ss.ss_quantity > 15 THEN 'High Qty' ELSE 'Low Qty' END AS quantity_category,
    ss.ss_ext_sales_price - ss.ss_ext_discount_amt AS net_sales_before_tax,
    ss.ss_ext_sales_price * (1 + ca.ca_gmt_offset / 24) AS adjusted_sales,
    CASE WHEN ca.ca_country = 'United States' THEN 'United States' ELSE 'United States' END AS region_type,
    ss.ss_ext_sales_price * ss.ss_quantity AS total_price,
    (ss.ss_ext_sales_price * ss.ss_quantity) - ss.ss_ext_discount_amt AS net_price
FROM store_sales ss
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'OK' AND ss.ss_sold_date_sk = 2451831
