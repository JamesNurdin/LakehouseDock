WITH intersect_customers AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
    INTERSECT
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_month = 5
)
SELECT
    cc.cc_name,
    cp.cp_description,
    rc.c_customer_id            AS refunded_customer_id,
    rca.ca_city                 AS refunded_city,
    ret.c_customer_id           AS returning_customer_id,
    retca.ca_city               AS returning_city,
    cr.cr_return_amount,
    CASE WHEN cr.cr_return_amount > 500 THEN 'High' ELSE 'Low' END AS amount_category,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY cr.cr_return_amount DESC) AS state_return_rank,
    lt.total_returns_by_customer
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer rc ON cr.cr_refunded_customer_sk = rc.c_customer_sk
JOIN customer_address rca ON cr.cr_refunded_addr_sk = rca.ca_address_sk
JOIN customer ret ON cr.cr_returning_customer_sk = ret.c_customer_sk
JOIN customer_address retca ON cr.cr_returning_addr_sk = retca.ca_address_sk
JOIN intersect_customers ic ON ic.cust_sk = rc.c_customer_sk
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS total_returns_by_customer
    FROM catalog_returns cr2
    WHERE cr2.cr_refunded_customer_sk = rc.c_customer_sk
) lt ON TRUE
WHERE
    cc.cc_company_name = 'pri'
    AND cc.cc_rec_end_date = DATE '2000-12-31'
    AND cp.cp_catalog_page_number IN (3, 10, 15)
    AND rc.c_birth_day IN (13, 23)
    AND rca.ca_state = 'CA'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_returning_customer_sk = ret.c_customer_sk
          AND cr3.cr_return_amount > 100
    )
ORDER BY state_return_rank, cr.cr_return_amount DESC
LIMIT 100
