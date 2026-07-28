WITH sales_by_state AS (
    SELECT
        ca.ca_state AS state,
        'sales_profit' AS metric,
        SUM(ss.ss_net_profit) AS amount
    FROM store_sales ss
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_wholesale_cost > 40
      AND ca.ca_gmt_offset = -5.00
    GROUP BY ca.ca_state
),
returns_by_state AS (
    SELECT
        ca.ca_state AS state,
        'return_loss' AS metric,
        SUM(sr.sr_net_loss) AS amount
    FROM store_returns sr
    INNER JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    INNER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%color%'
      AND ca.ca_gmt_offset = -5.00
    GROUP BY ca.ca_state
)
SELECT state, metric, amount
FROM sales_by_state
UNION ALL
SELECT state, metric, amount
FROM returns_by_state
ORDER BY state, metric
