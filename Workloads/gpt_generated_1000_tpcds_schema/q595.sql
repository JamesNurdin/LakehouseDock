WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > (
        SELECT MAX(ws_quantity)
        FROM web_sales ws
        WHERE ws.ws_ship_mode_sk = 3
    )
),
ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
)
SELECT
    customer.c_customer_sk,
    item.i_brand,
    household_demographics.hd_income_band_sk,
    ship_mode.sm_type,
    SUM(COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
    AVG(COALESCE(cs.cs_quantity, 0) + COALESCE(ws.ws_quantity, 0)) AS avg_quantity,
    COUNT(DISTINCT COALESCE(cs.cs_order_number, ws.ws_order_number)) AS distinct_orders,
    MIN(COALESCE(cs.cs_ext_sales_price, ws.ws_ext_sales_price)) AS min_sales,
    MAX(COALESCE(cs.cs_ext_sales_price, ws.ws_ext_sales_price)) AS max_sales
FROM cs
FULL OUTER JOIN ws
    ON cs.cs_item_sk = ws.ws_item_sk
    AND cs.cs_bill_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN customer
    ON (cs.cs_bill_customer_sk = customer.c_customer_sk OR ws.ws_bill_customer_sk = customer.c_customer_sk)
LEFT JOIN household_demographics
    ON (cs.cs_bill_hdemo_sk = household_demographics.hd_demo_sk OR ws.ws_bill_hdemo_sk = household_demographics.hd_demo_sk)
LEFT JOIN item
    ON (cs.cs_item_sk = item.i_item_sk OR ws.ws_item_sk = item.i_item_sk)
LEFT JOIN promotion
    ON (cs.cs_promo_sk = promotion.p_promo_sk OR ws.ws_promo_sk = promotion.p_promo_sk)
LEFT JOIN ship_mode
    ON (cs.cs_ship_mode_sk = ship_mode.sm_ship_mode_sk OR ws.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk)
LEFT JOIN inventory
    ON item.i_item_sk = inventory.inv_item_sk
LEFT JOIN web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
WHERE
    promotion.p_channel_demo = 'N'
    AND household_demographics.hd_income_band_sk = 10
    AND web_site.web_suite_number = 'Suite 210 '
    AND item.i_current_price > 100
GROUP BY CUBE (customer.c_customer_sk, item.i_brand, household_demographics.hd_income_band_sk, ship_mode.sm_type)
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
