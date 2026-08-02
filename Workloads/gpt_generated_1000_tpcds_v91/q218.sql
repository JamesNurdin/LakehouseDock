WITH sales_data AS (
    SELECT
        ws_site.web_name AS website_name,
        i.i_brand AS brand,
        hd_bill.hd_vehicle_count AS vehicle_count,
        i.i_item_sk AS item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_sales,
        MIN(ws.ws_ext_sales_price) AS min_sales,
        MAX(ws.ws_ext_sales_price) AS max_sales,
        SUM(CASE WHEN ws.ws_ext_sales_price > 500 THEN ws.ws_ext_sales_price ELSE 0 END) AS high_sales_sum,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
        (
            SELECT SUM(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
        ) AS total_promo_cost
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion promo ON ws.ws_promo_sk = promo.p_promo_sk AND promo.p_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE i.i_manufact_id IN (350, 167)
      AND i.i_class_id = 12
      AND i.i_units = 'Case'
      AND promo.p_channel_dmail = 'Y'
      AND promo.p_response_target = 1
      AND hd_bill.hd_dep_count >= 3
      AND hd_ship.hd_vehicle_count <= 2
      AND ws.ws_quantity > 1
      AND ws.ws_sold_date_sk BETWEEN 2450236 AND 2450633
      AND ws_site.web_state = 'CA'
    GROUP BY ws_site.web_name, i.i_brand, hd_bill.hd_vehicle_count, i.i_item_sk
)
SELECT
    website_name,
    brand,
    vehicle_count,
    item_sk,
    num_orders,
    total_sales,
    avg_sales,
    min_sales,
    max_sales,
    high_sales_sum,
    sales_category,
    total_promo_cost
FROM sales_data
ORDER BY total_sales DESC
LIMIT 100
