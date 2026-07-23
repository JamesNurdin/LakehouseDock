WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_code,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        time_dim.t_hour,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN time_dim ON ws.ws_sold_time_sk = time_dim.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        time_dim.t_hour BETWEEN 9 AND 17
        AND sm.sm_code = 'AIR'
        AND ib.ib_upper_bound > 100000
        AND ws.ws_quantity > 1
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_code,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        time_dim.t_hour
)
SELECT
    sm_ship_mode_id,
    sm_code,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    t_hour,
    total_net_paid,
    distinct_customers,
    avg_sales_price,
    total_net_paid / NULLIF(distinct_customers, 0) AS net_paid_per_customer
FROM sales_agg
WHERE distinct_customers >= 10
ORDER BY total_net_paid DESC
LIMIT 100
