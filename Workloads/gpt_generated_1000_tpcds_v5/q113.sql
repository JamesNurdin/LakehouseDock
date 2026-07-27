WITH return_stats AS (
    SELECT
        ca.ca_state AS state,
        'return' AS source,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS transaction_count,
        AVG(cr.cr_return_amount) AS avg_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc LIKE '%product%'
      AND cr.cr_return_amount > 0
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_addr_sk = cr.cr_refunded_addr_sk
            AND ss.ss_net_paid > 1000
      )
    GROUP BY ca.ca_state
),
sale_stats AS (
    SELECT
        ca.ca_state AS state,
        'sale' AS source,
        SUM(ss.ss_net_paid) AS total_amount,
        COUNT(*) AS transaction_count,
        AVG(ss.ss_net_paid) AS avg_amount
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ss.ss_net_paid > 0
    GROUP BY ca.ca_state
)
SELECT
    state,
    source,
    total_amount,
    transaction_count,
    avg_amount
FROM return_stats
UNION ALL
SELECT
    state,
    source,
    total_amount,
    transaction_count,
    avg_amount
FROM sale_stats
ORDER BY state, source
LIMIT 100
