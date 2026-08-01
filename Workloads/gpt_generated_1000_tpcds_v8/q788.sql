WITH sampled_calls AS (
    SELECT *
    FROM call_center
    TABLESAMPLE BERNOULLI (10)
)
SELECT *
FROM (
    SELECT
        cr.cr_item_sk AS item_sk,
        CASE WHEN cr.cr_return_amount > 500 THEN 'HIGH' ELSE 'LOW' END AS tier,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_item_sk ORDER BY cr.cr_return_amount DESC) AS rn,
        (
            SELECT SUM(ws2.ws_net_paid)
            FROM web_sales ws2
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            WHERE i2.i_item_sk = cr.cr_item_sk
        ) AS total_amount
    FROM catalog_returns cr
    FULL OUTER JOIN sampled_calls cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_amount IS NOT NULL
) AS a
INTERSECT
SELECT *
FROM (
    SELECT
        ws.ws_item_sk AS item_sk,
        CASE WHEN ws.ws_ext_sales_price > 2000 THEN 'HIGH' ELSE 'LOW' END AS tier,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn,
        (
            SELECT SUM(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            WHERE i2.i_item_sk = ws.ws_item_sk
        ) AS total_amount
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_ext_sales_price IS NOT NULL
) AS b
ORDER BY item_sk, tier, rn DESC
LIMIT 100
