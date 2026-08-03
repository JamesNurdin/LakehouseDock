/*
Goal: Summarize return activity per customer address (city + state) while categorizing refunded cash levels. 
The query demonstrates string processing (LIKE, REGEXP_LIKE, REGEXP_EXTRACT, concatenation), uses a RIGHT OUTER JOIN to keep all address rows even when there are no matching returns, and applies a LATERAL sub‑query that derives a cash‑category flag and extracts a numeric part from the reason surrogate key.
*/
WITH address_stats AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        regexp_extract(ca.ca_zip, '^([0-9]{3})', 1) AS zip_prefix
    FROM customer_address ca
    WHERE ca.ca_suite_number LIKE 'Suite %'                         -- suite numbers start with "Suite "
      AND regexp_like(ca.ca_city, '^[A-Z][a-z]+$')                  -- simple capitalised city name
)
SELECT
    a.city_state,
    a.zip_prefix,
    l.cash_category,
    COUNT(cr.cr_order_number)               AS num_returns,
    SUM(cr.cr_refunded_cash)                AS total_refunded_cash,
    SUM(cr.cr_net_loss)                     AS total_net_loss,
    AVG(cr.cr_return_quantity)              AS avg_return_qty
FROM catalog_returns cr
RIGHT OUTER JOIN address_stats a
    ON cr.cr_returning_addr_sk = a.ca_address_sk
CROSS JOIN LATERAL (
    SELECT
        CASE WHEN cr.cr_refunded_cash > 500 THEN 'HIGH' ELSE 'LOW' END AS cash_category,
        regexp_extract(CAST(cr.cr_reason_sk AS VARCHAR), '(\\d+)', 1) AS reason_code_extracted
) AS l
WHERE a.ca_city LIKE '%field%'                -- keep cities containing the word "field"
   OR a.ca_city LIKE '%ville%'
GROUP BY a.city_state, a.zip_prefix, l.cash_category
ORDER BY total_refunded_cash DESC
LIMIT 20
