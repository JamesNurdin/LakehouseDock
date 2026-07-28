WITH sub_a AS (
    SELECT
        sm1.sm_type AS category,
        CAST(d_sold.d_year AS VARCHAR) AS period,
        SUM(ws.ws_net_paid) AS metric
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm1
        ON ws.ws_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN warehouse w1
        ON ws.ws_warehouse_sk = w1.w_warehouse_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm2
        ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN store st
        ON st.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM store s2
          WHERE s2.s_closed_date_sk = ws.ws_ship_date_sk
            AND s2.s_state = 'CA'
      )
    GROUP BY sm1.sm_type, d_sold.d_year
),
sub_b AS (
    SELECT
        w2.w_state AS category,
        d_ship2.d_quarter_name AS period,
        SUM(ws.ws_net_profit) AS metric
    FROM web_sales ws
    JOIN date_dim d_ship2
        ON ws.ws_ship_date_sk = d_ship2.d_date_sk
    JOIN warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN ship_mode sm3
        ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
    JOIN date_dim d_sold2
        ON ws.ws_sold_date_sk = d_sold2.d_date_sk
    JOIN store st2
        ON st2.s_closed_date_sk = d_ship2.d_date_sk
    WHERE sm3.sm_contract = 'Ek'
    GROUP BY w2.w_state, d_ship2.d_quarter_name
)
SELECT
    category,
    period,
    SUM(metric) AS total_metric
FROM (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
) AS combined
GROUP BY category, period
HAVING SUM(metric) > 10000
ORDER BY total_metric DESC
LIMIT 100
