WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        r.r_reason_desc,
        ca.ca_state
    FROM catalog_returns cr
    JOIN customer cu
        ON cr.cr_refunded_customer_sk = cu.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_ship_cost > 50
      AND cr.cr_return_amt_inc_tax <= 2000
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_sk = cr.cr_reason_sk
            AND r2.r_reason_id = 'AAAAAAAAPAAAAAAA'
      )
),
agg AS (
    SELECT
        cr_reason_sk,
        r_reason_desc,
        ca_state,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(cr_return_quantity) AS total_qty
    FROM base
    GROUP BY ROLLUP (r_reason_desc, ca_state, cr_reason_sk)
)
SELECT
    r_reason_desc,
    ca_state,
    total_return_amount,
    return_cnt,
    avg_return_amount,
    CASE
        WHEN total_return_amount > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_level,
    (
        SELECT AVG(DISTINCT cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_reason_sk = agg.cr_reason_sk
    ) AS avg_distinct_amount_same_reason,
    ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY total_return_amount DESC) AS rn_reason
FROM agg
WHERE return_cnt > 0
ORDER BY r_reason_desc NULLS LAST, ca_state NULLS LAST
LIMIT 100
