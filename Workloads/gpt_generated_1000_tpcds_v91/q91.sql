WITH cust_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_centers,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages,
        COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_modes,
        COUNT(DISTINCT w.w_warehouse_id) AS distinct_warehouses,
        COUNT(DISTINCT r1.r_reason_id) AS distinct_catalog_return_reasons,
        COUNT(DISTINCT r2.r_reason_id) AS distinct_store_return_reasons,
        COUNT(DISTINCT wp_cust.wp_web_page_id) AS distinct_customer_pages,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(sr.sr_return_amt) AS total_store_returns,
        CASE
            WHEN ib.ib_upper_bound <= 30000 THEN 'Low'
            WHEN ib.ib_upper_bound <= 80000 THEN 'Medium'
            ELSE 'High'
        END AS income_category
    FROM customer c
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r1
        ON cr.cr_reason_sk = r1.r_reason_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_page wp_cust
        ON wp_cust.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE c.c_birth_year BETWEEN 1965 AND 1985
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
            AND cr2.cr_return_amount > 100
      )
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    ROW_NUMBER() OVER (ORDER BY (total_catalog_sales + total_web_sales - total_catalog_returns - total_store_returns) DESC) AS sales_rank,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.income_category,
    c.total_catalog_sales,
    c.total_web_sales,
    c.total_catalog_returns,
    c.total_store_returns,
    (c.total_catalog_sales + c.total_web_sales - c.total_catalog_returns - c.total_store_returns) AS net_sales
FROM cust_agg c
ORDER BY net_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
