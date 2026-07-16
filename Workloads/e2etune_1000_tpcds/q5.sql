SELECT ca.ca_city AS city,
       ca.ca_state AS state,
       cd.cd_gender AS gender,
       COUNT(DISTINCT wp.wp_web_page_sk) AS total_pages,
       COUNT(DISTINCT c.c_customer_sk) AS total_customers,
       SUM(wp.wp_char_count) AS total_characters,
       AVG(wp.wp_char_count) AS avg_characters_per_page,
       AVG(wp.wp_char_count) * 1.0 / NULLIF(COUNT(DISTINCT c.c_customer_sk), 0) AS avg_characters_per_customer,
       AVG(hd.hd_vehicle_count) AS avg_vehicle_count
FROM web_page wp
JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE wp.wp_rec_start_date >= DATE '2022-01-01'
  AND wp.wp_rec_end_date <= DATE '2022-12-31'
  AND cd.cd_gender = 'F'
  AND c.c_birth_year BETWEEN 1970 AND 1990
  AND ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY ca.ca_city, ca.ca_state, cd.cd_gender
HAVING COUNT(DISTINCT c.c_customer_sk) >= 100
ORDER BY total_pages DESC
LIMIT 10
