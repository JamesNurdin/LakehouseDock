SELECT ss.ss_sold_date_sk,
       ss.ss_sales_price,
       ss.ss_quantity,
       (ss.ss_sales_price * ss.ss_quantity) AS line_total,
       CASE WHEN ca.ca_state = 'KY' THEN 'East' ELSE 'Other' END AS region_flag,
       CASE WHEN ss.ss_sales_price > 41.44 THEN ss.ss_sales_price * 1.1 ELSE ss.ss_sales_price END AS adjusted_price
FROM store_sales ss
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ss.ss_sold_date_sk = 2452013
  AND ca.ca_country = 'United States'
