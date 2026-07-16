SELECT
    ca.ca_state,
    ca.ca_county,
    ca.ca_location_type,
    ib.ib_income_band_sk,
    COUNT(*) AS address_cnt,
    AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
    MIN(ib.ib_lower_bound) AS min_income,
    MAX(ib.ib_upper_bound) AS max_income
FROM
    customer_address ca
JOIN
    income_band ib
    ON CAST(ca.ca_zip AS integer) BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE
    ca.ca_location_type IN ('condo', 'single family')
    AND ca.ca_gmt_offset IS NOT NULL
GROUP BY
    ca.ca_state,
    ca.ca_county,
    ca.ca_location_type,
    ib.ib_income_band_sk
HAVING
    COUNT(*) > 5
ORDER BY
    address_cnt DESC,
    ca.ca_state,
    ca.ca_county
LIMIT 50
