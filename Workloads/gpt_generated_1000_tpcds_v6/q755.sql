WITH avg_refund AS (
    SELECT avg(cr_refunded_cash) AS avg_cash
    FROM catalog_returns
)
SELECT
    ca_r.ca_city AS city,
    SUM(cr_r.cr_refunded_cash) AS total_cash,
    'Refund' AS activity_type,
    CASE WHEN SUM(cr_r.cr_refunded_cash) > 1000 THEN 'High' ELSE 'Low' END AS cash_level,
    (SELECT avg_cash FROM avg_refund) AS overall_avg_refund
FROM catalog_returns cr_r
JOIN customer c_r
    ON cr_r.cr_refunded_customer_sk = c_r.c_customer_sk
JOIN customer_address ca_r
    ON cr_r.cr_refunded_addr_sk = ca_r.ca_address_sk
WHERE cr_r.cr_warehouse_sk = 5
  AND cr_r.cr_ship_mode_sk = 8
  AND EXISTS (
        SELECT 1
        FROM customer_address ca_chk
        WHERE ca_chk.ca_city = ca_r.ca_city
          AND ca_chk.ca_state = 'CA'
    )
GROUP BY ca_r.ca_city

UNION ALL

SELECT
    ca_ret.ca_city AS city,
    SUM(cr_ret.cr_return_amount) AS total_cash,
    'Return' AS activity_type,
    CASE WHEN SUM(cr_ret.cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS cash_level,
    (SELECT avg_cash FROM avg_refund) AS overall_avg_refund
FROM catalog_returns cr_ret
JOIN customer c_ret
    ON cr_ret.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_address ca_ret
    ON cr_ret.cr_returning_addr_sk = ca_ret.ca_address_sk
WHERE cr_ret.cr_warehouse_sk = 14
  AND cr_ret.cr_ship_mode_sk = 5
GROUP BY ca_ret.ca_city
ORDER BY total_cash DESC
LIMIT 100
