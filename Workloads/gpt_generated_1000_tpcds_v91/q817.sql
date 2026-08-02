WITH ws_agg AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS category,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS amount
    FROM date_dim d
    FULL OUTER JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, w.w_warehouse_name
),
sr_agg AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS category,
        -SUM(COALESCE(sr.sr_return_amt, 0)) AS amount
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ca.ca_state
),
combined AS (
    SELECT year, 'WEB_SALES' AS source_type, category, amount FROM ws_agg
    UNION ALL
    SELECT year, 'STORE_RETURNS' AS source_type, category, amount FROM sr_agg
)
SELECT DISTINCT year, source_type, category, amount
FROM combined
ORDER BY year, source_type, category
