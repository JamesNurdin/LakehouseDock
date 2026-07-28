WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        c_birth_country,
        REGEXP_EXTRACT(c_birth_country, '^([A-Z]+)') AS country_prefix,
        CASE
            WHEN REGEXP_LIKE(c_last_name, '^[AEIOUaeiou]') THEN 'StartsWithVowel'
            ELSE 'Other'
        END AS last_name_category
    FROM customer
    WHERE c_birth_country LIKE '%United%'
      AND REGEXP_LIKE(c_birth_country, '^[A-Z ]+$')
      AND REGEXP_LIKE(c_last_name, '.*[aeiouAEIOU].*')
)
SELECT
    fc.c_birth_country AS birth_country,
    td.t_hour AS return_hour,
    fc.last_name_category,
    fc.country_prefix,
    MIN(SUBSTR(fc.full_name, 1, 5)) AS name_prefix,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(CASE WHEN cr.cr_return_amount > 1000 THEN 1 ELSE 0 END) AS high_value_returns
FROM catalog_returns cr
JOIN filtered_customers fc
    ON cr.cr_refunded_customer_sk = fc.c_customer_sk
JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND REGEXP_LIKE(fc.full_name, '^.{1,10}$')
GROUP BY
    fc.c_birth_country,
    td.t_hour,
    fc.last_name_category,
    fc.country_prefix
ORDER BY total_return_amount DESC
LIMIT 100
