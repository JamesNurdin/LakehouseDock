WITH filtered_customers AS (
    SELECT c.*
    FROM customer c
    WHERE c.c_customer_sk IN (
        SELECT cr.cr_returning_customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
    )
)
SELECT
    promo_name,
    state,
    CASE WHEN total_sales > 0 THEN 'SALE' ELSE 'RETURN' END AS activity_type,
    total_sales,
    total_return_amount,
    total_sales - total_return_amount AS net_amount,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_band
FROM (
    SELECT
        p.p_promo_name AS promo_name,
        w.w_state AS state,
        SUM(ss.ss_net_paid) AS total_sales,
        0.0 AS total_return_amount
    FROM filtered_customers c
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr1 ON cr1.cr_returning_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cr1.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr1.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr1.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN customer_demographics cd_current ON c.c_current_cdemo_sk = cd_current.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ROLLUP (p.p_promo_name, w.w_state)
    UNION DISTINCT
    SELECT
        p.p_promo_name AS promo_name,
        w.w_state AS state,
        0.0 AS total_sales,
        SUM(cr2.cr_return_amount) AS total_return_amount
    FROM filtered_customers c
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr2 ON cr2.cr_refunded_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cr2.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr2.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN customer_demographics cd_current ON c.c_current_cdemo_sk = cd_current.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ROLLUP (p.p_promo_name, w.w_state)
) t
ORDER BY net_amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
