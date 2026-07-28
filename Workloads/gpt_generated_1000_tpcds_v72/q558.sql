WITH ws_agg AS (
    SELECT
        'WebSales' AS source,
        d.d_year AS year,
        w.w_state AS state,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        SUM(ws.ws_net_profit) AS total_profit,
        (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
      AND sm.sm_type = 'EXPRESS'
    GROUP BY GROUPING SETS (
        (d.d_year, w.w_state),
        (d.d_year),
        ()
    )
),
sr_agg AS (
    SELECT
        'StoreReturns' AS source,
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(sr.sr_return_amt) AS total_amount,
        -SUM(sr.sr_net_loss) AS total_profit,
        (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_profit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year > 1970
      AND NOT EXISTS (
            SELECT 1
            FROM web_sales ws
            JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
            WHERE ws.ws_bill_customer_sk = c.c_customer_sk
              AND d2.d_year = 2000
      )
    GROUP BY GROUPING SETS (
        (d.d_year, ca.ca_state),
        (d.d_year),
        ()
    )
)
SELECT source,
       year,
       state,
       total_amount,
       total_profit,
       overall_avg_profit
FROM (
    SELECT * FROM ws_agg
    UNION ALL
    SELECT * FROM sr_agg
) AS combined
ORDER BY source, year, state
