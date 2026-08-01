WITH union_data AS (
    -- First branch with a Bernoulli sample and a set of filters
    SELECT
        cd.cd_gender,
        hd.hd_income_band_sk,
        CASE WHEN sm.sm_carrier = 'AIRBORNE' THEN 'Air' ELSE 'Other' END AS carrier_type,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_order_number
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_carrier = 'AIRBORNE'
      AND hd.hd_dep_count = 3
      AND wp.wp_image_count >= 4
      AND cs.cs_quantity > 5
      AND NOT EXISTS (
            SELECT 1 FROM web_sales ws2
            WHERE ws2.ws_order_number = cs.cs_order_number
              AND ws2.ws_item_sk = cs.cs_item_sk
              AND ws2.ws_sold_date_sk <> cs.cs_sold_date_sk
        )

    UNION

    -- Second branch with a different predicate set
    SELECT
        cd.cd_gender,
        hd.hd_income_band_sk,
        CASE WHEN sm.sm_carrier = 'AIRBORNE' THEN 'Air' ELSE 'Other' END AS carrier_type,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_code = 'AIR'
      AND wp.wp_rec_start_date = DATE '1999-09-04'
      AND hd.hd_dep_count = 1
      AND ws.ws_quantity > 2
      AND NOT EXISTS (
            SELECT 1 FROM web_page wp2
            WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
              AND wp2.wp_type = 'promo'
        )
)
SELECT
    cd_gender,
    hd_income_band_sk,
    carrier_type,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_ext_sales_price) AS avg_catalog_sale,
    MIN(cs_ext_sales_price) AS min_catalog_sale,
    MAX(cs_ext_sales_price) AS max_catalog_sale
FROM union_data
GROUP BY cd_gender, hd_income_band_sk, carrier_type
ORDER BY total_catalog_sales DESC
LIMIT 100
