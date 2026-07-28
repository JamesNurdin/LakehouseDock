WITH joined_data AS (
    SELECT
        cc.cc_name,
        cp.cp_catalog_page_number,
        c.c_customer_id,
        ca.ca_state,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        p.p_promo_name,
        td.t_hour,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        (ss.ss_ext_sales_price + ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END AS quantity_category,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY (ss.ss_ext_sales_price + ws.ws_ext_sales_price) DESC) AS state_sales_rank
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE td.t_hour BETWEEN 8 AND 16
      AND c.c_birth_year = 1980
      AND cd.cd_marital_status = 'M'
      AND cp.cp_catalog_page_number IN (1, 3, 8)
      AND p.p_discount_active = 'Y'
      AND cc.cc_country = 'United States'
)
SELECT *
FROM joined_data
LIMIT 100
