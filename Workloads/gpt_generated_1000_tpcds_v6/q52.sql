WITH sales AS (
    SELECT
        ca.ca_state AS state,
        'sales' AS metric,
        SUM(cs.cs_net_paid_inc_ship) AS amount
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE dd.d_year = 2001
    GROUP BY ca.ca_state
),
returns AS (
    SELECT
        ca.ca_state AS state,
        'returns' AS metric,
        SUM(wr.wr_net_loss) AS amount
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE dd.d_year = 2001
    GROUP BY ca.ca_state
),
combined AS (
    SELECT state, metric, amount FROM sales
    UNION ALL
    SELECT state, metric, amount FROM returns
)
SELECT
    state,
    metric,
    amount,
    row_number() OVER (PARTITION BY metric ORDER BY amount DESC) AS metric_rank
FROM combined
ORDER BY metric, amount DESC
LIMIT 100
