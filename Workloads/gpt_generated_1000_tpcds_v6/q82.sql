WITH filtered_returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_store_credit,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_street_name,
        ca.ca_zip,
        concat(ca.ca_street_number, ' ', ca.ca_street_name) AS full_street,
        regexp_extract(ca.ca_street_name, '(\\w+)$', 1) AS last_word
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_street_name, '^J.*')
      AND ca.ca_city LIKE 'A%'
      AND length(ca.ca_zip) = 5
)
SELECT
    city,
    state,
    count(DISTINCT sr_customer_sk) AS unique_customers,
    sum(sr_return_amt) AS total_return_amount,
    avg(sr_return_tax) AS avg_return_tax,
    sum(sr_store_credit) AS total_store_credit,
    max(last_word) AS most_common_last_word
FROM filtered_returns
GROUP BY city, state
ORDER BY total_return_amount DESC
LIMIT 100
