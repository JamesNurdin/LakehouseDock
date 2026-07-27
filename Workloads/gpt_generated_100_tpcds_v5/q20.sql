WITH distinct_returns AS (
    SELECT DISTINCT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_order_number,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 20.00
      AND cr.cr_return_quantity >= 10
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    SUM(dr.cr_return_amount) AS total_return_amount,
    AVG(dr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT dr.cr_order_number) AS distinct_orders,
    COUNT(*) AS total_returns
FROM distinct_returns dr
JOIN customer c
    ON dr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON dr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE c.c_birth_day = 23
  AND ca.ca_city = 'Oakland'
GROUP BY GROUPING SETS (
    (c.c_customer_id, ca.ca_city),
    (c.c_customer_id),
    (ca.ca_city),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
