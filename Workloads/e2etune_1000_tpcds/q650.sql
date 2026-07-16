SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    COUNT(DISTINCT ca.ca_address_sk) AS total_customers,
    ROUND(AVG(cd.cd_purchase_estimate), 2) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    COUNT(CASE WHEN cd.cd_education_status = 'College' THEN 1 END) AS college_educated_customers,
    t.min_hour,
    t.max_hour
FROM customer_address ca
JOIN customer_demographics cd
  ON ca.ca_address_sk = cd.cd_demo_sk
JOIN store s
  ON ca.ca_city = s.s_city
 AND ca.ca_state = s.s_state
 AND ca.ca_gmt_offset = s.s_gmt_offset
JOIN (
    SELECT MIN(t_hour) AS min_hour,
           MAX(t_hour) AS max_hour
    FROM time_dim
    WHERE t_shift = 'Morning'
) t
  ON 1 = 1
WHERE ca.ca_country = 'United States'
  AND s.s_closed_date_sk IS NULL
GROUP BY s.s_store_name, s.s_city, s.s_state, t.min_hour, t.max_hour
HAVING COUNT(DISTINCT ca.ca_address_sk) > 10
ORDER BY total_customers DESC
LIMIT 100
