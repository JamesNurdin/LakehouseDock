WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_call_center_sk,
        cr.cr_returning_customer_sk
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_name, '(?i)north|south')
      AND c.c_email_address LIKE '%.com'
      AND d.d_year = 1912
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    concat(cc.cc_city, ', ', cc.cc_state) AS location,
    MIN(regexp_extract(cc.cc_manager, '^([^ ]+)', 1)) AS manager_first_name,
    COUNT(fr.cr_return_quantity) AS total_returns,
    SUM(fr.cr_return_amount) AS total_return_amount
FROM filtered_returns fr
JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_refunded_customer_sk = fr.cr_returning_customer_sk
      AND cr2.cr_returned_date_sk = fr.cr_returned_date_sk
)
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state
ORDER BY total_return_amount DESC
LIMIT 100
