SELECT cd.cd_gender AS gender,
       cd.cd_marital_status AS marital_status,
       ca.ca_city AS city,
       hd.hd_buy_potential AS buy_potential,
       COUNT(*) AS total_pages,
       COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
       COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
       SUM(wp.wp_char_count) AS total_characters,
       AVG(wp.wp_link_count) AS avg_links_per_page,
       SUM(wp.wp_char_count) / NULLIF(SUM(wp.wp_link_count), 0) AS avg_chars_per_link,
       AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
       AVG(hd.hd_vehicle_count) AS avg_vehicle_count
FROM web_page wp
JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE wp.wp_type = 'Product'
  AND wp.wp_rec_start_date >= DATE '2022-01-01'
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year >= 1970
GROUP BY cd.cd_gender, cd.cd_marital_status, ca.ca_city, hd.hd_buy_potential
HAVING COUNT(*) > 50
ORDER BY total_pages DESC
LIMIT 100
