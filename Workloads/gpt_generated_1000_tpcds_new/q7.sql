WITH base1 AS (
    SELECT
        wh.w_warehouse_id AS warehouse_id,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        hd.hd_buy_potential AS buy_potential,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        ROW_NUMBER() OVER (
            PARTITION BY wh.w_warehouse_id, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
            ORDER BY SUM(ws.ws_net_paid) DESC
        ) AS rn
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE ib.ib_upper_bound >= 50000
      AND ib.ib_lower_bound <= 150000
      AND wh.w_gmt_offset = -5.00
      AND wh.w_country = 'United States'
      AND hd.hd_dep_count <= 5
      AND hd.hd_buy_potential IN ('5001-10000', '1001-5000')
      AND ws.ws_quantity > 2
    GROUP BY wh.w_warehouse_id, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
),
base2 AS (
    SELECT
        wh.w_warehouse_id AS warehouse_id,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        hd.hd_buy_potential AS buy_potential,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        ROW_NUMBER() OVER (
            PARTITION BY wh.w_warehouse_id, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
            ORDER BY SUM(ws.ws_net_paid) DESC
        ) AS rn
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE ib.ib_upper_bound <= 200000
      AND ib.ib_lower_bound >= 60001
      AND wh.w_gmt_offset = -6.00
      AND wh.w_country = 'United States'
      AND hd.hd_dep_count >= 0
      AND hd.hd_buy_potential = '0-500'
      AND ws.ws_ext_discount_amt < 500
    GROUP BY wh.w_warehouse_id, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
)
SELECT
    warehouse_id,
    lower_bound,
    upper_bound,
    buy_potential,
    total_net_paid,
    avg_net_profit,
    order_cnt
FROM (
    SELECT warehouse_id, lower_bound, upper_bound, buy_potential, total_net_paid, avg_net_profit, order_cnt, rn
    FROM base1
    UNION DISTINCT
    SELECT warehouse_id, lower_bound, upper_bound, buy_potential, total_net_paid, avg_net_profit, order_cnt, rn
    FROM base2
) u
WHERE rn <= 5
ORDER BY total_net_paid DESC
LIMIT 100
