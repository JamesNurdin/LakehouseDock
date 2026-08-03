WITH base_a AS (
    SELECT
        cr.cr_returning_addr_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_state AS refunded_state,
        CASE
            WHEN cr.cr_return_amount > 500 THEN 'HIGH'
            WHEN cr.cr_return_amount > 200 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS amount_level
    FROM catalog_returns cr
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE cr.cr_return_amount > 150                          -- predicate 1
      AND cr.cr_return_quantity >= 2                         -- predicate 2
      AND cr.cr_return_ship_cost < 1500                      -- predicate 3
      AND ca_ret.ca_gmt_offset BETWEEN -8.00 AND -6.00       -- predicate 4
      AND ca_ref.ca_state = 'TX'                             -- predicate 5
),
base_b AS (
    SELECT
        cr.cr_returning_addr_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_state AS refunded_state,
        CASE
            WHEN cr.cr_return_amount > 500 THEN 'HIGH'
            WHEN cr.cr_return_amount > 200 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS amount_level
    FROM catalog_returns cr
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE cr.cr_return_amount BETWEEN 100 AND 300            -- predicate 1b
      AND cr.cr_return_quantity = 1                         -- predicate 2b
      AND cr.cr_return_ship_cost < 1000                     -- predicate 3b
      AND ca_ret.ca_gmt_offset = -7.00                      -- predicate 4b
      AND ca_ref.ca_state IN ('CA', 'NY')                   -- predicate 5b
),
union_base AS (
    SELECT
        cr_returning_addr_sk,
        cr_refunded_addr_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_ship_cost,
        returning_state,
        refunded_state,
        amount_level
    FROM base_a
    UNION DISTINCT
    SELECT
        cr_returning_addr_sk,
        cr_refunded_addr_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_ship_cost,
        returning_state,
        refunded_state,
        amount_level
    FROM base_b
),
grouped AS (
    SELECT
        amount_level,
        returning_state,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_return_quantity) AS sum_quantity,
        COUNT(*) AS cnt_rows
    FROM union_base
    GROUP BY amount_level, returning_state
)
SELECT
    g.amount_level,
    g.returning_state,
    g.sum_return_amount,
    g.sum_quantity,
    g.cnt_rows,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE CASE
                  WHEN cr2.cr_return_amount > 500 THEN 'HIGH'
                  WHEN cr2.cr_return_amount > 200 THEN 'MEDIUM'
                  ELSE 'LOW'
              END = g.amount_level
    ) AS avg_return_amount_by_level,
    CASE
        WHEN g.sum_quantity > 20 THEN 'VERY HIGH'
        WHEN g.sum_quantity > 10 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS quantity_band
FROM grouped g
WHERE g.sum_return_amount > 200   -- outer filter predicate 1
  AND g.cnt_rows >= 2            -- outer filter predicate 2
ORDER BY g.sum_return_amount DESC
LIMIT 100
