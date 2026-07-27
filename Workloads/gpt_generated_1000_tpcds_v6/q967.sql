WITH cc_open AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        d.d_date AS open_date
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_city, '^San')
),
ws_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        d.d_date AS sold_date,
        ws.ws_warehouse_sk,
        hd.hd_income_band_sk,
        ib.ib_upper_bound
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 50000
)
SELECT
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    concat(cc.cc_city, ', ', cc.cc_state) AS location_label,
    sum(ws.ws_net_profit) AS total_profit
FROM cc_open cc
JOIN ws_filtered ws
    ON cc.open_date = ws.sold_date
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_zip LIKE '7%'
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    concat(cc.cc_city, ', ', cc.cc_state)
ORDER BY total_profit DESC
LIMIT 100
