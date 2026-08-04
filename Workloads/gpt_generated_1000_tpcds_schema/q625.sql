WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        i.i_brand,
        i.i_brand_id,
        i.i_item_desc,
        p.p_promo_name,
        sm.sm_carrier,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS extracted_code,
        LAG(ws.ws_net_profit) OVER (PARTITION BY i.i_brand ORDER BY ws.ws_sold_date_sk) AS lag_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_item_desc, '[A-Za-z]{5,}\\s[0-9]{3}')
      AND p.p_promo_name LIKE '%sale%'
      AND sm.sm_carrier = 'UPS'
      AND ws.ws_net_profit > 0
),
order_exceptions AS (
    SELECT ws_order_number FROM web_sales WHERE ws_ext_sales_price > 5000
    EXCEPT
    SELECT ws_order_number FROM web_sales WHERE ws_quantity < 5
),
order_common AS (
    SELECT ws_order_number FROM web_sales WHERE ws_ship_mode_sk IN (
        SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type LIKE 'AIR%'
    )
    INTERSECT
    SELECT ws_order_number FROM web_sales WHERE ws_promo_sk IN (
        SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'Y'
    )
),
union_aggregates AS (
    SELECT i.i_brand AS agg_key, SUM(ws.ws_net_profit) AS total_profit, 'brand' AS agg_type
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_brand
    UNION
    SELECT i.i_category AS agg_key, SUM(ws.ws_net_profit) AS total_profit, 'category' AS agg_type
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category
)
SELECT
    fs.i_brand,
    fs.i_item_desc,
    CONCAT(fs.i_brand, '-', CAST(fs.i_brand_id AS VARCHAR)) AS brand_key,
    fs.extracted_code,
    fs.ws_net_profit,
    fs.lag_profit,
    (SELECT MAX(p_cost) FROM promotion WHERE p_promo_sk = fs.ws_promo_sk) AS max_promo_cost,
    CASE
        WHEN fs.ws_order_number IN (SELECT ws_order_number FROM order_exceptions) THEN 'exception'
        WHEN fs.ws_order_number IN (SELECT ws_order_number FROM order_common) THEN 'common'
        ELSE 'regular'
    END AS order_group,
    ua.total_profit,
    ua.agg_type
FROM filtered_sales fs
LEFT JOIN union_aggregates ua
    ON ua.agg_type = 'brand' AND ua.agg_key = fs.i_brand
WHERE fs.rn = 1
ORDER BY fs.lag_profit DESC NULLS LAST, ua.total_profit DESC
LIMIT 100
