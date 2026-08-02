WITH intersected_warehouses AS (
    SELECT cs.cs_warehouse_sk AS warehouse_sk
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_list_price > 150
      AND cs.cs_quantity > 5
      AND sm.sm_code = 'AIR'
      AND sm.sm_carrier = 'MSC'
      AND hd.hd_income_band_sk = 3
    INTERSECT
    SELECT ws.ws_warehouse_sk
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_list_price > 150
      AND ws.ws_quantity > 5
      AND sm.sm_code = 'AIR'
      AND sm.sm_carrier = 'MSC'
      AND hd.hd_income_band_sk = 3
),
base_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        w.w_city AS city,
        sm_cs.sm_code AS ship_mode_code,
        hd_cs.hd_income_band_sk AS income_band,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        AVG(cs.cs_quantity) AS avg_catalog_quantity,
        AVG(ws.ws_quantity) AS avg_web_quantity,
        MIN(cs.cs_sales_price) AS min_catalog_sales_price,
        MAX(ws.ws_sales_price) AS max_web_sales_price
    FROM catalog_sales cs
    JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE sm_cs.sm_code = 'AIR'
      AND sm_cs.sm_carrier = 'MSC'
      AND w.w_state = 'CA'
      AND w.w_warehouse_sq_ft > 700000
      AND hd_cs.hd_income_band_sk = 3
      AND hd_cs.hd_vehicle_count >= 2
      AND i.inv_quantity_on_hand > 1000
      AND cs.cs_list_price > 150
      AND cs.cs_quantity BETWEEN 5 AND 20
      AND sm_ws.sm_code = 'AIR'
      AND sm_ws.sm_carrier = 'MSC'
      AND we.web_country = 'US'
      AND wp.wp_type = 'content'
      AND w.w_warehouse_sk IN (SELECT warehouse_sk FROM intersected_warehouses)
    GROUP BY w.w_warehouse_id, w.w_city, sm_cs.sm_code, hd_cs.hd_income_band_sk
    HAVING SUM(cs.cs_net_profit) > 100000
       AND SUM(ws.ws_net_profit) > 100000
)
SELECT
    warehouse_id,
    city,
    ship_mode_code,
    income_band,
    catalog_orders,
    web_orders,
    total_catalog_profit,
    total_web_profit,
    avg_catalog_quantity,
    avg_web_quantity,
    min_catalog_sales_price,
    max_web_sales_price,
    SUM(total_catalog_profit) OVER (ORDER BY total_catalog_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_catalog_profit,
    RANK() OVER (ORDER BY total_web_profit DESC) AS web_profit_rank
FROM base_agg
ORDER BY total_catalog_profit DESC
LIMIT 100
