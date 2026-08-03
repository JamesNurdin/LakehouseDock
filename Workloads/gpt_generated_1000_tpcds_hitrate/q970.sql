WITH base AS (
    SELECT
        i.i_brand,
        i.i_container,
        sm.sm_carrier,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_net_profit > 0
      AND REGEXP_LIKE(i.i_brand, '^import')
      AND sm.sm_carrier LIKE 'A%'
),
aggregated AS (
    SELECT
        b.i_brand,
        b.sm_carrier,
        b.i_container,
        SUM(b.ws_net_profit) AS total_net_profit,
        SUM(b.ws_ext_sales_price) AS total_sales,
        CASE
            WHEN SUM(b.ws_net_profit) > 10000 THEN 'HIGH'
            WHEN SUM(b.ws_net_profit) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_tier,
        CONCAT(b.i_brand, '-', COALESCE(b.i_container, 'UNKNOWN')) AS brand_container,
        (SELECT MAX(b2.ws_ext_discount_amt)
         FROM base b2
         WHERE b2.i_brand = b.i_brand) AS max_discount_for_brand
    FROM base b
    GROUP BY CUBE(b.i_brand, b.sm_carrier, b.i_container)
)
SELECT *
FROM (
    SELECT
        a.i_brand,
        a.sm_carrier,
        a.i_container,
        a.total_net_profit,
        a.total_sales,
        a.profit_tier,
        a.brand_container,
        a.max_discount_for_brand,
        ROW_NUMBER() OVER (PARTITION BY a.i_brand ORDER BY a.total_net_profit DESC) AS rn
    FROM aggregated a
) t
WHERE rn <= 5
ORDER BY i_brand, rn
LIMIT 100
