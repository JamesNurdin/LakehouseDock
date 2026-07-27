WITH
sales_joined AS (
    SELECT
        ws.ws_bill_hdemo_sk AS demo_sk,
        'profit' AS metric_type,
        SUM(ws.ws_net_profit) AS metric_value,
        sm.sm_ship_mode_id AS ship_mode_id,
        CAST(NULL AS varchar) AS reason_desc,
        ca.ca_city AS city
    FROM tpcds.web_sales ws
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_wholesale_cost > 10
      AND ws.ws_list_price > 20
      AND ws.ws_ext_tax > 0
      AND sm.sm_carrier = 'FEDEX'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ws.ws_bill_hdemo_sk, sm.sm_ship_mode_id, ca.ca_city
),
returns_joined AS (
    SELECT
        wr.wr_refunded_hdemo_sk AS demo_sk,
        'return' AS metric_type,
        SUM(wr.wr_return_amt) AS metric_value,
        CAST(NULL AS varchar) AS ship_mode_id,
        r.r_reason_desc AS reason_desc,
        CAST(NULL AS varchar) AS city
    FROM tpcds.web_returns wr
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY wr.wr_refunded_hdemo_sk, r.r_reason_desc
),
combined AS (
    SELECT * FROM sales_joined
    UNION ALL
    SELECT * FROM returns_joined
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    combined.metric_type,
    COALESCE(combined.ship_mode_id, 'N/A') AS ship_mode_id,
    AVG(combined.metric_value) AS avg_metric_value,
    COUNT(DISTINCT combined.demo_sk) AS distinct_demo_cnt
FROM combined
JOIN tpcds.household_demographics hd
    ON combined.demo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    combined.metric_type,
    combined.ship_mode_id
HAVING AVG(combined.metric_value) > 1000
ORDER BY ib.ib_upper_bound DESC, avg_metric_value DESC
