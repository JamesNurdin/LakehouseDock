WITH addr_intersect AS (
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_gmt_offset = -5.00
    INTERSECT
    SELECT cr_refunded_addr_sk
    FROM catalog_returns
    WHERE cr_return_ship_cost > 1000
),
joined_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_refunded_cash,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk,
        cr.cr_return_ship_cost,
        cr.cr_return_quantity,
        ca_ref.ca_state AS refunded_state,
        ca_ref.ca_city AS refunded_city,
        ca_ref.ca_street_name AS refunded_street_name,
        ca_ref.ca_street_number AS refunded_street_number,
        ca_ref.ca_street_type AS refunded_street_type,
        ca_ref.ca_address_sk AS refunded_address_sk,
        ca_ret.ca_state AS returning_state,
        ca_ret.ca_city AS returning_city,
        ca_ret.ca_street_name AS returning_street_name,
        ca_ret.ca_street_number AS returning_street_number,
        ca_ret.ca_street_type AS returning_street_type,
        ca_ret.ca_address_sk AS returning_address_sk
    FROM catalog_returns cr
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE cr.cr_return_amount > 0
      AND ca_ref.ca_address_sk IN (SELECT ca_address_sk FROM addr_intersect)
      AND ca_ret.ca_address_sk IN (SELECT ca_address_sk FROM addr_intersect)
      AND regexp_like(ca_ref.ca_street_name, '^[A-Z][a-z]+')
      AND ca_ret.ca_city LIKE 'S%'
)
SELECT
    jr.refunded_state,
    jr.returning_state,
    COUNT(*) AS total_returns,
    SUM(jr.cr_return_amount) AS total_return_amount,
    AVG(jr.cr_return_tax) AS avg_return_tax,
    (
        SELECT SUM(cr3.cr_refunded_cash)
        FROM catalog_returns cr3
        JOIN customer_address ca3
            ON cr3.cr_refunded_addr_sk = ca3.ca_address_sk
        WHERE ca3.ca_state = jr.refunded_state
    ) AS total_refunded_cash_refunded_state,
    (
        SELECT SUM(cr3.cr_refunded_cash)
        FROM catalog_returns cr3
        JOIN customer_address ca3
            ON cr3.cr_returning_addr_sk = ca3.ca_address_sk
        WHERE ca3.ca_state = jr.returning_state
    ) AS total_refunded_cash_returning_state,
    ANY_VALUE(regexp_extract(jr.refunded_street_name, '^([A-Za-z]+)', 1)) AS refunded_street_prefix,
    ANY_VALUE(CONCAT(jr.refunded_street_number, ' ', jr.refunded_street_name, ' ', jr.refunded_street_type)) AS refunded_full_address,
    ANY_VALUE(CONCAT(jr.returning_street_number, ' ', jr.returning_street_name, ' ', jr.returning_street_type)) AS returning_full_address
FROM joined_returns jr
GROUP BY
    jr.refunded_state,
    jr.returning_state
HAVING
    COUNT(*) >= 5
ORDER BY
    total_return_amount DESC
LIMIT 100
