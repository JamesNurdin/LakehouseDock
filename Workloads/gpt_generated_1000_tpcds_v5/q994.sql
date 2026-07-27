WITH returns_detail AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_reversed_charge,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_location_type,
        ca.ca_suite_number,
        ca.ca_street_type,
        cd.cd_gender,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(ca.ca_city, '^A.*')                     -- cities that start with 'A'
      AND ca.ca_location_type LIKE '%family%'                -- address type contains the word "family"
)
SELECT
    rd.ca_city,
    rd.ca_state,
    concat(rd.ca_city, ', ', rd.ca_state) AS city_state,
    COUNT(*) AS return_cnt,
    SUM(rd.sr_return_amt) AS total_return_amt,
    CASE
        WHEN SUM(rd.sr_return_amt) >= 1000 THEN 'High'
        WHEN SUM(rd.sr_return_amt) >= 500  THEN 'Medium'
        ELSE 'Low'
    END AS return_level,
    MIN(regexp_extract(rd.ca_suite_number, '(\\d+)', 1)) AS example_suite_digits,
    MIN(substr(rd.ca_zip, 1, 5)) AS zip_prefix
FROM returns_detail rd
WHERE rd.sr_return_ship_cost > 10
  AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = rd.sr_customer_sk
          AND sr3.sr_return_amt > 200
        LIMIT 1
    )
GROUP BY rd.ca_city, rd.ca_state
ORDER BY total_return_amt DESC
LIMIT 100
