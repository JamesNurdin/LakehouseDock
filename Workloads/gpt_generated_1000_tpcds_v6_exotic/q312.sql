WITH store_returns_agg AS (
    SELECT
        metric_type,
        state,
        metric_value,
        ROW_NUMBER() OVER (ORDER BY metric_value DESC) AS metric_rank
    FROM (
        SELECT
            'store_return' AS metric_type,
            ca.ca_state AS state,
            SUM(sr.sr_return_amt_inc_tax) AS metric_value
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2000
        GROUP BY ca.ca_state
    ) sr_agg
),
web_site_agg AS (
    SELECT
        metric_type,
        state,
        metric_value,
        ROW_NUMBER() OVER (ORDER BY metric_value DESC) AS metric_rank
    FROM (
        SELECT
            'web_site' AS metric_type,
            ws.web_state AS state,
            AVG(ws.web_tax_percentage) AS metric_value
        FROM web_site ws
        JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
        GROUP BY ws.web_state
    ) ws_agg
)
SELECT metric_type, state, metric_value, metric_rank
FROM store_returns_agg
UNION ALL
SELECT metric_type, state, metric_value, metric_rank
FROM web_site_agg
ORDER BY metric_type, metric_value DESC
LIMIT 100
