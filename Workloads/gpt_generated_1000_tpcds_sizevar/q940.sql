WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),

-- Order numbers present in both catalog and web sales
intersected_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM cs_sample cs
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_state = 'CA'
),

aggregated_cs AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS sold_date_sk,
        cp.cp_department,
        NULL AS page_type,
        sm.sm_carrier,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
        (
            SELECT COALESCE(SUM(cr2.cr_return_amount), 0)
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
        ) AS total_return_amount
    FROM cs_sample cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cs.cs_order_number NOT IN (SELECT cr_order_number FROM catalog_returns)
    GROUP BY cs.cs_order_number, cs.cs_sold_date_sk, cp.cp_department, sm.sm_carrier
),

aggregated_ws AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS sold_date_sk,
        NULL AS cp_department,
        wp.wp_type AS page_type,
        sm.sm_carrier,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 20000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
        (
            SELECT COALESCE(SUM(cr3.cr_return_amount), 0)
            FROM catalog_returns cr3
            WHERE cr3.cr_order_number = ws.ws_order_number
        ) AS total_return_amount
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_b ON ws.ws_bill_addr_sk = ca_b.ca_address_sk
    JOIN customer_address ca_s ON ws.ws_ship_addr_sk = ca_s.ca_address_sk
    JOIN customer_demographics cd_b ON ws.ws_bill_cdemo_sk = cd_b.cd_demo_sk
    JOIN customer_demographics cd_s ON ws.ws_ship_cdemo_sk = cd_s.cd_demo_sk
    JOIN household_demographics hd_b ON ws.ws_bill_hdemo_sk = hd_b.hd_demo_sk
    JOIN household_demographics hd_s ON ws.ws_ship_hdemo_sk = hd_s.hd_demo_sk
    WHERE ws.ws_order_number NOT IN (SELECT cr_order_number FROM catalog_returns)
    GROUP BY ws.ws_order_number, ws.ws_sold_date_sk, wp.wp_type, sm.sm_carrier
),

combined AS (
    SELECT * FROM aggregated_cs
    UNION
    SELECT * FROM aggregated_ws
)

SELECT
    c.order_number,
    c.sold_date_sk,
    c.cp_department,
    c.page_type,
    c.sm_carrier,
    c.total_sales,
    c.sales_category,
    c.total_return_amount
FROM combined c
WHERE c.order_number IN (SELECT order_number FROM intersected_orders)
ORDER BY c.total_sales DESC
LIMIT 100
