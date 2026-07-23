WITH promo_union AS (
    SELECT cs.cs_promo_sk AS promo_sk FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_promo_sk AS promo_sk FROM store_sales ss
)
SELECT
    t.t_hour AS hour,
    cc.cc_market_manager AS market_manager,
    sm.sm_code AS ship_code,
    cp.cp_department AS department,
    SUM(cs.cs_ext_sales_price + ss.ss_ext_sales_price + ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE WHEN SUM(cs.cs_ext_sales_price + ss.ss_ext_sales_price + ws.ws_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
    (SELECT MAX(p2.p_cost) FROM promotion p2) AS max_promo_cost,
    (SELECT COUNT(DISTINCT promo_sk) FROM promo_union) AS distinct_promo_count
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    AND cs.cs_ship_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    AND cs.cs_ship_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    AND cs.cs_ship_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    AND cs.cs_ship_customer_sk = c.c_customer_sk
    AND c.c_current_cdemo_sk = cd.cd_demo_sk
    AND c.c_current_hdemo_sk = hd.hd_demo_sk
    AND c.c_current_addr_sk = ca.ca_address_sk
JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    AND ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_cdemo_sk = cd.cd_demo_sk
    AND ss.ss_hdemo_sk = hd.hd_demo_sk
    AND ss.ss_addr_sk = ca.ca_address_sk
    AND ss.ss_promo_sk = p.p_promo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_ship_customer_sk = c.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_bill_addr_sk = ca.ca_address_sk
    AND ws.ws_ship_addr_sk = ca.ca_address_sk
    AND ws.ws_promo_sk = p.p_promo_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE
    cc.cc_market_manager = 'Kim Wilson'
    AND sm.sm_code = 'AIR'
    AND c.c_birth_country = 'MONACO'
    AND t.t_hour BETWEEN 9 AND 17
    AND ib.ib_lower_bound >= 50000
    AND EXISTS (
        SELECT 1 FROM income_band ib2
        WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
          AND ib2.ib_upper_bound <= 100000
    )
GROUP BY
    t.t_hour,
    cc.cc_market_manager,
    sm.sm_code,
    cp.cp_department
ORDER BY
    total_sales DESC,
    hour ASC
LIMIT 100
