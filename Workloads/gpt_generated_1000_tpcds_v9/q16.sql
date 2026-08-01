WITH sales_base AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_net_paid,
        i.i_category,
        ca.ca_state,
        hd.hd_vehicle_count,
        i.i_current_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price > 5.00
      AND hd.hd_vehicle_count >= 0
),
returns_base AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_return_amt,
        i.i_category,
        ca.ca_state,
        hd.hd_vehicle_count,
        i.i_current_price
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price > 5.00
      AND hd.hd_vehicle_count >= 0
)
SELECT
    category,
    state,
    total_amount,
    metric_type
FROM (
    SELECT
        s.i_category AS category,
        s.ca_state AS state,
        SUM(s.ws_net_paid) AS total_amount,
        'sale' AS metric_type
    FROM sales_base s
    GROUP BY ROLLUP(s.i_category, s.ca_state)
    HAVING SUM(s.ws_net_paid) > 1000

    UNION ALL

    SELECT
        r.i_category AS category,
        r.ca_state AS state,
        SUM(r.wr_return_amt) AS total_amount,
        'return' AS metric_type
    FROM returns_base r
    GROUP BY ROLLUP(r.i_category, r.ca_state)
    HAVING SUM(r.wr_return_amt) > 500
) AS combined
ORDER BY
    category ASC NULLS LAST,
    state ASC NULLS LAST,
    metric_type
LIMIT 100
