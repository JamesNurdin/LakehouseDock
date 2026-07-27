WITH filtered_addresses AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        concat(ca_city, ', ', ca_state) AS city_state,
        regexp_extract(ca_state, '^([A-Z]{2})', 1) AS state_code,
        regexp_extract(ca_zip, '(\\d+)', 1) AS zip_numeric
    FROM customer_address
    WHERE regexp_like(ca_city, '^San')
      AND ca_zip LIKE '9%'
)
SELECT
    fa.state_code,
    COUNT(sr.sr_ticket_number) AS returns_count,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_quantity,
    MAX(fa.zip_numeric) AS max_zip_numeric
FROM store_returns sr
JOIN filtered_addresses fa ON sr.sr_addr_sk = fa.ca_address_sk
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
WHERE td.t_meal_time = 'dinner'
  AND EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_refunded_addr_sk = fa.ca_address_sk
        AND cr.cr_return_amount > 0
  )
GROUP BY fa.state_code
ORDER BY total_net_loss DESC
LIMIT 10
