WITH catalog AS (
    SELECT
        cs_ship_mode_sk,
        cs_net_paid,
        cs_ext_discount_amt,
        cs_net_profit,
        cs_quantity
    FROM catalog_sales
    WHERE cs_quantity > 0
),
web AS (
    SELECT
        ws_ship_mode_sk,
        ws_net_paid,
        ws_ext_discount_amt,
        ws_net_profit,
        ws_quantity
    FROM web_sales
    WHERE ws_quantity > 0
),
combined AS (
    SELECT
        cs_ship_mode_sk AS ship_mode_sk,
        'catalog' AS channel,
        cs_net_paid AS net_paid,
        cs_ext_discount_amt AS discount_amt,
        cs_net_profit AS net_profit,
        cs_quantity AS quantity
    FROM catalog
    UNION ALL
    SELECT
        ws_ship_mode_sk AS ship_mode_sk,
        'web' AS channel,
        ws_net_paid AS net_paid,
        ws_ext_discount_amt AS discount_amt,
        ws_net_profit AS net_profit,
        ws_quantity AS quantity
    FROM web
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    combined.channel,
    SUM(combined.net_paid) AS total_net_paid,
    SUM(combined.discount_amt) AS total_discount,
    SUM(combined.net_profit) AS total_net_profit,
    SUM(combined.quantity) AS total_quantity,
    AVG(combined.net_paid) AS avg_net_paid
FROM combined
JOIN ship_mode sm
    ON combined.ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_type,
    combined.channel
ORDER BY total_net_paid DESC
LIMIT 10
