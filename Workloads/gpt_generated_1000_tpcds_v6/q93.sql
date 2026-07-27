WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        sm.sm_code,
        sm.sm_type,
        cd.cd_gender,
        cd.cd_marital_status,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_net_paid_inc_ship >= 500
)
SELECT
    brand,
    product_prefix,
    sales_cnt,
    total_profit,
    avg_profit,
    promo_label,
    avg_discount_for_promo
FROM (
    -- Sales with a promotion whose name contains "Discount"
    SELECT
        sd.i_brand AS brand,
        REGEXP_EXTRACT(sd.i_product_name, '^(\\w+)', 1) AS product_prefix,
        COUNT(*) AS sales_cnt,
        SUM(sd.ws_net_profit) AS total_profit,
        AVG(sd.ws_net_profit) AS avg_profit,
        CONCAT('Promo-', COALESCE(sd.p_promo_name, 'NONE')) AS promo_label,
        (
            SELECT AVG(inner_ws.ws_ext_discount_amt)
            FROM web_sales inner_ws
            WHERE inner_ws.ws_promo_sk = sd.ws_promo_sk
        ) AS avg_discount_for_promo
    FROM sales_data sd
    WHERE sd.p_promo_name IS NOT NULL
      AND REGEXP_LIKE(sd.p_promo_name, '.*Discount.*')
      AND sd.sm_code LIKE 'AIR%'
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = sd.ws_ship_mode_sk
            AND sm2.sm_type LIKE 'OVER%'
      )
    GROUP BY
        sd.i_brand,
        REGEXP_EXTRACT(sd.i_product_name, '^(\\w+)', 1),
        sd.p_promo_name,
        sd.ws_promo_sk
    UNION ALL
    -- Sales without a matching "Discount" promotion (or no promotion at all)
    SELECT
        sd.i_brand AS brand,
        REGEXP_EXTRACT(sd.i_product_name, '^(\\w+)', 1) AS product_prefix,
        COUNT(*) AS sales_cnt,
        SUM(sd.ws_net_profit) AS total_profit,
        AVG(sd.ws_net_profit) AS avg_profit,
        'NoPromo' AS promo_label,
        NULL AS avg_discount_for_promo
    FROM sales_data sd
    WHERE (sd.p_promo_name IS NULL OR NOT REGEXP_LIKE(sd.p_promo_name, '.*Discount.*'))
      AND sd.sm_code LIKE 'AIR%'
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = sd.ws_ship_mode_sk
            AND sm2.sm_type LIKE 'OVER%'
      )
    GROUP BY
        sd.i_brand,
        REGEXP_EXTRACT(sd.i_product_name, '^(\\w+)', 1)
) combined
ORDER BY total_profit DESC, sales_cnt DESC
LIMIT 100
