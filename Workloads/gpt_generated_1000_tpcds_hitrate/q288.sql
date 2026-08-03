WITH filtered_returns AS (
   SELECT
       sr.sr_returned_date_sk,
       sr.sr_return_amt,
       sr.sr_return_quantity,
       ca.ca_city,
       ca.ca_state,
       d.d_year,
       d.d_date
   FROM store_returns sr
   JOIN date_dim d
       ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer_address ca
       ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2002
     AND regexp_like(ca.ca_city, 'Park')
)
SELECT
    fr.ca_city,
    fr.ca_state,
    COUNT(*) AS total_returns,
    SUM(fr.sr_return_amt) AS total_return_amount,
    AVG(fr.sr_return_amt) AS avg_return_amount,
    CASE
        WHEN SUM(fr.sr_return_amt) > 5000 THEN 'High'
        ELSE 'Normal'
    END AS return_category,
    MAX(fr.d_date) AS last_return_date,
    regexp_extract(fr.ca_city, '^(\\w+)', 1) AS city_first_word,
    CONCAT(fr.ca_city, ', ', fr.ca_state) AS full_location,
    CASE
        WHEN LOWER(fr.ca_city) LIKE '%highland%' THEN 'Highland Area'
        ELSE 'Other'
    END AS city_group,
    ws.web_name,
    CASE
        WHEN regexp_like(ws.web_name, 'Online') THEN 'Online Site'
        ELSE 'Other Site'
    END AS site_type
FROM filtered_returns fr
JOIN web_site ws
    ON ws.web_open_date_sk = fr.sr_returned_date_sk
WHERE ws.web_name IS NOT NULL
GROUP BY
    fr.ca_city,
    fr.ca_state,
    ws.web_name
ORDER BY total_return_amount DESC
LIMIT 100
