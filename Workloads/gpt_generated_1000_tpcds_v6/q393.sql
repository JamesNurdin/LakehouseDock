WITH item_sales_agg AS (
    SELECT
        ws_item_sk,
        ws_warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(*) AS order_cnt
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_ext_sales_price > 0
      AND ws_ship_mode_sk IS NOT NULL
    GROUP BY ws_item_sk, ws_warehouse_sk
),
rep_sales AS (
    SELECT
        ws_item_sk,
        ws_warehouse_sk,
        MIN(ws_bill_hdemo_sk) AS bill_hdemo_sk,
        MIN(ws_ship_mode_sk) AS ship_mode_sk,
        MIN(ws_web_site_sk) AS web_site_sk
    FROM web_sales
    GROUP BY ws_item_sk, ws_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    hd.hd_vehicle_count,
    sm.sm_carrier,
    ws_agg.total_sales,
    ws_agg.total_quantity,
    ws_agg.order_cnt,
    ROUND(ws_agg.total_sales / NULLIF(ws_agg.order_cnt, 0), 2) AS avg_sales_per_order,
    (SELECT AVG(i_current_price) FROM item WHERE i_brand = i.i_brand) AS brand_avg_price,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY ws_agg.total_sales DESC) AS sales_rank_in_warehouse,
    ROW_NUMBER() OVER (ORDER BY ws_agg.total_sales DESC) AS overall_sales_rn
FROM item_sales_agg ws_agg
JOIN rep_sales rs
    ON ws_agg.ws_item_sk = rs.ws_item_sk
   AND ws_agg.ws_warehouse_sk = rs.ws_warehouse_sk
JOIN item i
    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON rs.bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
    ON rs.ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws
    ON rs.web_site_sk = ws.web_site_sk
WHERE i.i_current_price > 20.00
  AND i.i_brand = 'Brand#12'
  AND w.w_warehouse_sq_ft > 500000
  AND sm.sm_carrier = 'Carrier#2'
  AND hd.hd_vehicle_count >= 1
  AND ws.web_state = 'CA'
ORDER BY ws_agg.total_sales DESC
LIMIT 100
