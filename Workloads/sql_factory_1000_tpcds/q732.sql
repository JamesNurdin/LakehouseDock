WITH sales_by_address AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_state
),
returns_by_address AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_state,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_state
)
SELECT
    s.ca_state,
    s.ca_address_sk,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE
        WHEN s.total_sales = 0 THEN 0
        ELSE COALESCE(r.total_returns, 0) / s.total_sales
    END AS return_rate,
    DENSE_RANK() OVER (PARTITION BY s.ca_state ORDER BY CASE WHEN s.total_sales = 0 THEN 0 ELSE COALESCE(r.total_returns, 0) / s.total_sales END DESC) AS state_return_rate_rank,
    CASE
        WHEN CASE WHEN s.total_sales = 0 THEN 0 ELSE COALESCE(r.total_returns, 0) / s.total_sales END > 0.20 THEN 'High Return'
        ELSE 'Normal'
    END AS return_flag
FROM sales_by_address s
LEFT JOIN returns_by_address r
    ON s.ca_address_sk = r.ca_address_sk
WHERE s.total_sales > 0
ORDER BY s.ca_state, state_return_rate_rank
LIMIT 20
