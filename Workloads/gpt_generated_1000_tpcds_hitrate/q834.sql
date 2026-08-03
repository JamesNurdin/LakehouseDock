WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_ext_discount_amt,
        ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_bill_hdemo_sk IN (
        SELECT hd.hd_demo_sk
        FROM household_demographics hd
        WHERE hd.hd_buy_potential = '5001-10000'
    )
),
site_aggregates AS (
    SELECT
        fs.ws_web_site_sk,
        COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
        SUM(DISTINCT fs.ws_ext_discount_amt) AS distinct_discount_sum,
        SUM(fs.ws_net_paid_inc_tax) AS total_net_paid
    FROM filtered_sales fs
    GROUP BY fs.ws_web_site_sk
)
SELECT
    u.ws_web_site_sk,
    u.demo_sk,
    u.hd_income_band_sk,
    u.ws_net_paid_inc_tax,
    u.rn,
    wsit.web_name,
    sa.distinct_orders,
    sa.distinct_discount_sum
FROM (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_bill_hdemo_sk AS demo_sk,
        hd.hd_income_band_sk,
        ws.ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS rn
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_promo_sk = 804

    UNION ALL

    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_hdemo_sk AS demo_sk,
        hd.hd_income_band_sk,
        ws.ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS rn
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_promo_sk = 1456
) AS u
FULL OUTER JOIN web_site wsit
    ON u.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN site_aggregates sa
    ON wsit.web_site_sk = sa.ws_web_site_sk
ORDER BY u.ws_net_paid_inc_tax DESC
LIMIT 100
