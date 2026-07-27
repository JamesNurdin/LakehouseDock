WITH refunded_addr AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_returned_date_sk,
        ca.ca_suite_number,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_suite_number, '^Suite [A-Z]+$')
      AND ca.ca_city LIKE '%York%'
)
SELECT
    concat(cc.cc_name, ' (', cc.cc_city, ')') AS call_center_label,
    cc.cc_state,
    count(*) AS total_returns,
    sum(r.cr_return_amount) AS total_return_amount,
    avg(r.cr_return_tax) AS avg_return_tax,
    count(DISTINCT r.ca_zip) AS distinct_refunded_zip,
    (SELECT count(*) FROM call_center c2 WHERE c2.cc_state = cc.cc_state) AS centers_in_state
FROM refunded_addr r
JOIN call_center cc
    ON r.cr_call_center_sk = cc.cc_call_center_sk
WHERE substring(r.ca_suite_number, 7) LIKE 'S%'
GROUP BY
    concat(cc.cc_name, ' (', cc.cc_city, ')'),
    cc.cc_state
HAVING sum(r.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
