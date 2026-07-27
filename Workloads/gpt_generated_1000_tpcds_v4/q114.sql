WITH
    -- Base item dimension (used twice under different aliases)
    item_sales AS (
        SELECT
            i1.i_item_sk,
            i1.i_category,
            i1.i_brand,
            i1.i_product_name,
            ss.ss_sold_date_sk,
            ss.ss_ext_sales_price AS store_ext_sales,
            s.s_state,
            c_sales.c_customer_sk,
            cd_sales.cd_gender,
            hd_sales.hd_vehicle_count,
            cr.cr_return_amount,
            ws.ws_ext_sales_price AS web_ext_sales,
            cc.cc_name,
            sm_cr.sm_type AS return_ship_type,
            sm_ws.sm_type AS web_ship_type,
            r.r_reason_desc,
            site.web_name
        FROM
            item i1
            JOIN store_sales ss ON ss.ss_item_sk = i1.i_item_sk
            JOIN customer c_sales ON ss.ss_customer_sk = c_sales.c_customer_sk
            JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
            JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
            JOIN store s ON ss.ss_store_sk = s.s_store_sk
            -- second alias of the item table to link web sales to the same item
            JOIN item i2 ON i2.i_item_sk = i1.i_item_sk
            JOIN web_sales ws ON ws.ws_item_sk = i2.i_item_sk
            JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
            JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
            JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
            JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
            JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
            JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
            JOIN catalog_returns cr ON cr.cr_item_sk = i1.i_item_sk
            JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
            JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
            JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
            JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    )
SELECT
    s_state,
    i_category,
    SUM(store_ext_sales) AS total_store_sales,
    SUM(web_ext_sales)   AS total_web_sales,
    SUM(cr_return_amount) AS total_return_amount,
    CASE WHEN SUM(store_ext_sales) > 0
        THEN SUM(web_ext_sales) / SUM(store_ext_sales)
        ELSE NULL
    END AS web_to_store_sales_ratio
FROM
    item_sales
GROUP BY
    s_state,
    i_category
ORDER BY
    total_store_sales DESC
LIMIT 100
