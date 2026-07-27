WITH sales_by_class AS (
    SELECT
        i.i_class,
        sm.sm_type,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ext_sales_price > 500
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
    GROUP BY i.i_class, sm.sm_type
)
SELECT
    sbc.i_class AS item_class,
    sbc.sm_type AS ship_type,
    sbc.total_sales
FROM sales_by_class sbc
WHERE sbc.sm_type = 'EXPRESS'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
        WHERE i2.i_class = sbc.i_class
          AND ws2.ws_promo_sk > 800
    )
UNION ALL
SELECT
    sbc.i_class AS item_class,
    sbc.sm_type AS ship_type,
    sbc.total_sales
FROM sales_by_class sbc
WHERE sbc.sm_type = 'OVERNIGHT'
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
        WHERE i2.i_class = sbc.i_class
          AND ws2.ws_promo_sk > 800
    )
ORDER BY item_class, ship_type
LIMIT 100
