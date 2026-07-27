WITH
    high_low_ship_modes AS (
        SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'UPS'
        UNION
        SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'USPS' AND sm_type = 'AIR'
    ),
    item_filtered AS (
        SELECT i_item_sk, i_category FROM item WHERE i_current_price > 100
    ),
    base AS (
        SELECT
            i.i_category,
            sm.sm_carrier,
            ws.ws_net_profit,
            ws.ws_list_price,
            cd.cd_gender,
            hd.hd_buy_potential,
            sm.sm_ship_mode_sk,
            ws.ws_item_sk
        FROM web_sales ws
        JOIN item_filtered i ON ws.ws_item_sk = i.i_item_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        WHERE ws.ws_list_price > 50
          AND ws.ws_net_profit > 0
          AND cd.cd_gender = 'M'
          AND hd.hd_buy_potential = '501-1000'
          AND sm.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM high_low_ship_modes)
    ),
    aggregated AS (
        SELECT
            b.i_category,
            b.sm_carrier,
            SUM(b.ws_net_profit) AS total_net_profit,
            COUNT(*) AS sales_cnt
        FROM base b
        GROUP BY b.i_category, b.sm_carrier
        HAVING SUM(b.ws_net_profit) > (SELECT AVG(ws3.ws_net_profit) FROM web_sales ws3)
    )
SELECT
    a.i_category,
    a.sm_carrier,
    a.total_net_profit,
    a.sales_cnt,
    RANK() OVER (PARTITION BY a.sm_carrier ORDER BY a.total_net_profit DESC) AS category_rank,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_net_profit
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 10
