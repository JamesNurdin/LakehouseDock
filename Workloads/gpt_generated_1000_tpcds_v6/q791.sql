WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_hdemo_sk,
        cs_catalog_page_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        COUNT(*) AS cnt_catalog_sales
    FROM catalog_sales
    WHERE cs_list_price > 120
    GROUP BY cs_call_center_sk, cs_ship_mode_sk, cs_warehouse_sk, cs_bill_hdemo_sk, cs_catalog_page_sk
),
ws_agg AS (
    SELECT
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_bill_hdemo_sk,
        ws_web_page_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(*) AS cnt_web_sales
    FROM web_sales
    WHERE ws_ext_tax > 20
    GROUP BY ws_ship_mode_sk, ws_warehouse_sk, ws_bill_hdemo_sk, ws_web_page_sk
)
SELECT
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    wp.wp_type AS web_page_type,
    cs_agg.total_catalog_sales,
    ws_agg.total_web_sales,
    (cs_agg.total_catalog_sales + ws_agg.total_web_sales) AS total_combined_sales,
    (cs_agg.total_catalog_sales + ws_agg.total_web_sales) /
        NULLIF(cs_agg.cnt_catalog_sales + ws_agg.cnt_web_sales, 0) AS avg_sales_per_order
FROM cs_agg
JOIN ws_agg
    ON cs_agg.cs_ship_mode_sk = ws_agg.ws_ship_mode_sk
   AND cs_agg.cs_warehouse_sk = ws_agg.ws_warehouse_sk
   AND cs_agg.cs_bill_hdemo_sk = ws_agg.ws_bill_hdemo_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp
    ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE cc.cc_state = 'CA'
  AND w.w_city = 'New York'
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND cs_agg.total_catalog_sales > 10000
  AND ws_agg.total_web_sales > 5000
ORDER BY total_combined_sales DESC
LIMIT 100
