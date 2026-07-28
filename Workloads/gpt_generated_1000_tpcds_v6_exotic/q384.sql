WITH catalog_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        i.i_category AS category,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        'Catalog' AS channel,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
        (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category = i.i_category) AS avg_category_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_category = 'Sports'
      AND EXISTS (
          SELECT 1 FROM ship_mode sm
          WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
            AND sm.sm_type = 'AIR'
      )
    GROUP BY cs.cs_item_sk, i.i_category
),
web_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        'Web' AS channel,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
        (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category = i.i_category) AS avg_category_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Sports'
      AND EXISTS (
          SELECT 1 FROM ship_mode sm
          WHERE sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
            AND sm.sm_type = 'AIR'
      )
    GROUP BY ws.ws_item_sk, i.i_category
)
SELECT
    item_sk,
    category,
    channel,
    net_paid,
    net_profit,
    profit_status,
    avg_category_price,
    CASE WHEN net_paid > avg_category_price * 100 THEN 'High Volume' ELSE 'Normal Volume' END AS volume_category
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
ORDER BY net_paid DESC
LIMIT 100
