WITH sub_a AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_type AS ship_type,
        SUM(cs.cs_ext_sales_price) AS sum_cs_ext_sales,
        SUM(ws.ws_ext_sales_price) AS sum_ws_ext_sales,
        SUM(cs.cs_quantity) AS sum_cs_quantity,
        SUM(ws.ws_quantity) AS sum_ws_quantity,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
                       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                       AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
    WHERE p.p_purpose = 'Unknown'
      AND sm.sm_type = 'AIR'
      AND td.t_hour = 14
    GROUP BY CUBE(cp.cp_department, sm.sm_type)
),
sub_b AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_type AS ship_type,
        SUM(cs.cs_ext_sales_price) AS sum_cs_ext_sales,
        SUM(ws.ws_ext_sales_price) AS sum_ws_ext_sales,
        SUM(cs.cs_quantity) AS sum_cs_quantity,
        SUM(ws.ws_quantity) AS sum_ws_quantity,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
                       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                       AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
    WHERE p.p_channel_tv = 'N'
      AND sm.sm_type = 'GROUND'
      AND td.t_hour = 9
    GROUP BY CUBE(cp.cp_department, sm.sm_type)
)
SELECT
    department,
    ship_type,
    (sum_cs_ext_sales + sum_ws_ext_sales) AS total_ext_sales,
    (sum_cs_quantity + sum_ws_quantity) AS total_quantity,
    txn_count
FROM sub_a
UNION ALL
SELECT
    department,
    ship_type,
    (sum_cs_ext_sales + sum_ws_ext_sales) AS total_ext_sales,
    (sum_cs_quantity + sum_ws_quantity) AS total_quantity,
    txn_count
FROM sub_b
ORDER BY department, ship_type, total_ext_sales DESC
LIMIT 100
