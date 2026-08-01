WITH sales AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(cs.cs_net_paid_inc_ship_tax) AS amount,
        COUNT(*) AS transaction_cnt,
        'sales' AS metric
    FROM catalog_sales cs
    INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND w.w_state IN ('CA', 'TX')
    GROUP BY d.d_year, ca.ca_state
),
returns AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(sr.sr_return_amt) AS amount,
        COUNT(*) AS transaction_cnt,
        'returns' AS metric
    FROM store_returns sr
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY d.d_year, ca.ca_state
),
combined AS (
    SELECT year, state, amount, transaction_cnt, metric FROM sales
    UNION ALL
    SELECT year, state, amount, transaction_cnt, metric FROM returns
)
SELECT
    year,
    state,
    amount,
    transaction_cnt,
    metric
FROM combined
ORDER BY year DESC, state, metric
LIMIT 100
