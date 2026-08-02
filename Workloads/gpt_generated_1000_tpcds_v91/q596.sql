WITH ca_dist AS (
    SELECT DISTINCT ca_address_sk, ca_city, ca_state
    FROM customer_address
),
cat_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        ca_dist.ca_city,
        sm.sm_type,
        SUM(cs.cs_net_paid) AS total_sales,
        REGEXP_EXTRACT(cp.cp_description, '(\\d+)', 1) AS extracted_str,
        CONCAT('CC_', cc.cc_call_center_id) AS concat_str,
        CASE WHEN REGEXP_LIKE(cc.cc_name, '\\d') THEN 'HasDigit' ELSE 'NoDigit' END AS flag
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN ca_dist ON cs.cs_bill_addr_sk = ca_dist.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cp.cp_type LIKE 'A%'
      AND REGEXP_LIKE(cp.cp_description, '\\d')
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        ca_dist.ca_city,
        sm.sm_type,
        cp.cp_description,
        cc.cc_call_center_id,
        cc.cc_name
),
cat_final AS (
    SELECT
        w_warehouse_name AS warehouse_name,
        ca_city AS city,
        sm_type AS ship_type,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank,
        (SELECT SUM(i.inv_quantity_on_hand)
         FROM inventory i
         WHERE i.inv_warehouse_sk = w_warehouse_sk) AS total_inventory,
        extracted_str,
        concat_str,
        flag
    FROM cat_agg
),
web_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        ca_dist.ca_city,
        sm.sm_type,
        SUM(ws.ws_net_paid) AS total_sales,
        REGEXP_EXTRACT(wp.wp_url, '([a-z]+)\\.com', 1) AS extracted_str,
        CONCAT('WP_', wp.wp_type) AS concat_str,
        CASE WHEN wp.wp_url LIKE '%/promo%' THEN 'Promo' ELSE 'Regular' END AS flag
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN ca_dist ON ws.ws_bill_addr_sk = ca_dist.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type LIKE 'Content%'
      AND REGEXP_LIKE(wp.wp_url, '^https?://')
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        ca_dist.ca_city,
        sm.sm_type,
        wp.wp_url,
        wp.wp_type
),
web_final AS (
    SELECT
        w_warehouse_name AS warehouse_name,
        ca_city AS city,
        sm_type AS ship_type,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank,
        (SELECT SUM(i.inv_quantity_on_hand)
         FROM inventory i
         WHERE i.inv_warehouse_sk = w_warehouse_sk) AS total_inventory,
        extracted_str,
        concat_str,
        flag
    FROM web_agg
)
SELECT *
FROM cat_final
UNION DISTINCT
SELECT *
FROM web_final
ORDER BY warehouse_name, city, total_sales DESC
