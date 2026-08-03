WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_web_site_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451180
      AND ws_ship_mode_sk = 20
    GROUP BY ws_item_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_web_site_sk
),

first_set AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        ws_agg.total_net_paid,
        ws_agg.order_cnt,
        CASE WHEN ws_agg.total_net_paid > 100000 THEN 'High' ELSE 'Low' END AS revenue_bucket
    FROM ws_agg
    JOIN item i ON ws_agg.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr TABLESAMPLE BERNOULLI (10) ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN web_site web ON ws_agg.ws_web_site_sk = web.web_site_sk
    WHERE cc.cc_company = 5
      AND cp.cp_department = 'Sports'
      AND i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND hd_ret.hd_vehicle_count >= 1
      AND hd_ref.hd_dep_count = 0
),

second_set AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        ws_agg.total_net_paid,
        ws_agg.order_cnt,
        CASE WHEN ws_agg.total_net_paid > 50000 THEN 'Medium' ELSE 'Low' END AS revenue_bucket
    FROM ws_agg
    JOIN item i ON ws_agg.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr TABLESAMPLE BERNOULLI (10) ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN web_site web ON ws_agg.ws_web_site_sk = web.web_site_sk
    WHERE cc.cc_company = 3
      AND cp.cp_department = 'Books'
      AND i.i_brand = 'Brand#34'
      AND sm.sm_type = 'RAIL'
      AND web.web_company_id = 2
      AND hd_ret.hd_vehicle_count >= 2
      AND hd_ref.hd_dep_count = 1
)

SELECT i_item_id,
       i_brand,
       i_category,
       cc_name,
       cp_department,
       sm_type,
       w_warehouse_name,
       total_net_paid,
       order_cnt,
       revenue_bucket
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS rk
    FROM (
        SELECT * FROM first_set
        UNION DISTINCT
        SELECT * FROM second_set
    ) u
) ranked
WHERE rk <= 5
ORDER BY i_category, total_net_paid DESC
LIMIT 100
