WITH web_sales_summary AS (
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        SUM(ws.ws_net_paid) AS total_amount,
        'web_sales' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND ca.ca_location_type = 'apartment'
    GROUP BY ca.ca_state, d.d_year
),
store_returns_summary AS (
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        SUM(sr.sr_net_loss) AS total_amount,
        'store_returns' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND ca.ca_location_type = 'condo'
    GROUP BY ca.ca_state, d.d_year
)
SELECT state, year, total_amount, channel
FROM web_sales_summary
UNION ALL
SELECT state, year, total_amount, channel
FROM store_returns_summary
ORDER BY state, year, channel
LIMIT 100
