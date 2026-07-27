WITH refunded_addr AS (
    SELECT ca_address_sk,
           ca_state,
           ca_gmt_offset
    FROM   customer_address
    WHERE  ca_state IN ('CA', 'TX', 'NY')
),
returning_addr AS (
    SELECT ca_address_sk,
           ca_city
    FROM   customer_address
    WHERE  ca_suite_number LIKE 'Suite %'
)
SELECT
    ca_refunded.ca_state,
    ca_refunded.ca_gmt_offset,
    COUNT(DISTINCT cr.cr_order_number)                     AS orders_cnt,
    SUM(cr.cr_return_amount)                              AS total_return_amount,
    AVG(cr.cr_return_tax)                                 AS avg_return_tax,
    MIN(cr.cr_return_quantity)                           AS min_quantity,
    MAX(cr.cr_return_quantity)                           AS max_quantity,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM   catalog_returns cr2
        WHERE  cr2.cr_ship_mode_sk = 12
    )                                                    AS avg_return_amount_shipmode_12
FROM   catalog_returns cr
JOIN   refunded_addr ca_refunded
       ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN   returning_addr ca_returning
       ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
WHERE  cr.cr_ship_mode_sk IN (1, 3, 12)
  AND  cr.cr_return_amt_inc_tax > 100.00
  AND  cr.cr_return_quantity BETWEEN 1 AND 10
  AND  ca_refunded.ca_gmt_offset = -5.00
  AND  ca_returning.ca_city LIKE 'A%'
GROUP BY
    ca_refunded.ca_state,
    ca_refunded.ca_gmt_offset
ORDER BY
    total_return_amount DESC
LIMIT 100
