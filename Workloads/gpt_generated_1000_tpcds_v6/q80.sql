WITH bill_sales AS (
        SELECT
            p.p_promo_id,
            hd.hd_buy_potential,
            SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
            COUNT(*) AS order_cnt
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        WHERE p.p_channel_event = 'N'
          AND hd.hd_dep_count > 2
        GROUP BY p.p_promo_id, hd.hd_buy_potential
    ),
    ship_sales AS (
        SELECT
            p.p_promo_id,
            hd.hd_buy_potential,
            SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
            COUNT(*) AS order_cnt
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
        WHERE p.p_channel_radio = 'N'
          AND hd.hd_income_band_sk >= 13
        GROUP BY p.p_promo_id, hd.hd_buy_potential
    ),
    combined AS (
        SELECT * FROM bill_sales
        UNION ALL
        SELECT * FROM ship_sales
    )
SELECT
    p_promo_id,
    hd_buy_potential,
    total_net_paid,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_net_paid DESC) AS rn
FROM combined
ORDER BY total_net_paid DESC
LIMIT 100
