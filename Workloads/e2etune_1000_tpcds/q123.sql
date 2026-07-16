SELECT
    ca.ca_state,
    COUNT(DISTINCT ca.ca_address_id) AS num_customers,
    AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
    SUM(CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_days
FROM
    customer_address ca
JOIN
    date_dim d
    ON ca.ca_gmt_offset = CASE d.d_dow
        WHEN 1 THEN -5.00
        WHEN 2 THEN -6.00
        WHEN 3 THEN -7.00
        WHEN 4 THEN -8.00
        ELSE -5.00
    END
WHERE
    ca.ca_country = 'United States'
    AND d.d_year = 2022
    AND ca.ca_state IN ('AZ', 'NM', 'PA', 'CO')
GROUP BY
    ca.ca_state
HAVING
    COUNT(*) > 5
ORDER BY
    avg_gmt_offset DESC,
    num_customers DESC
LIMIT 20
