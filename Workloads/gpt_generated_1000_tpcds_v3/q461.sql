WITH cs_agg AS (
    SELECT
        cs_promo_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        cs_ship_hdemo_sk,
        cs_ship_addr_sk,
        SUM(cs_ext_sales_price) AS cs_total_sales,
        SUM(cs_quantity) AS cs_total_quantity,
        COUNT(*) AS cs_order_count
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450830 AND 2450900
    GROUP BY cs_promo_sk,
             cs_call_center_sk,
             cs_catalog_page_sk,
             cs_ship_mode_sk,
             cs_warehouse_sk,
             cs_bill_hdemo_sk,
             cs_bill_addr_sk,
             cs_ship_hdemo_sk,
             cs_ship_addr_sk
)
SELECT
    p_cat.p_promo_name AS promo_name,
    cc.cc_name AS call_center_name,
    cp.cp_department AS department,
    s.s_store_name AS store_name,
    ws_site.web_name AS web_site_name,
    SUM(cs_agg.cs_total_sales) AS catalog_sales_total,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(sr.sr_return_amt) AS total_returns,
    CASE
        WHEN SUM(cs_agg.cs_total_sales) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) > 50000 THEN 'High'
        ELSE 'Low'
    END AS sales_category,
    COUNT(*) AS record_count,
    AVG(ib.ib_lower_bound) AS avg_income_lower_bound
FROM cs_agg
JOIN promotion p_cat
    ON cs_agg.cs_promo_sk = p_cat.p_promo_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cs
    ON cs_agg.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse wh_cs
    ON cs_agg.cs_warehouse_sk = wh_cs.w_warehouse_sk
JOIN household_demographics hd_bill
    ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs_agg.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_bill
    ON cs_agg.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs_agg.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss
    ON ss.ss_promo_sk = p_cat.p_promo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p_store
    ON ss.ss_promo_sk = p_store.p_promo_sk
JOIN household_demographics hd_store
    ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd_return
    ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
JOIN customer_address ca_return
    ON sr.sr_addr_sk = ca_return.ca_address_sk
JOIN web_sales ws
    ON ws.ws_promo_sk = p_cat.p_promo_sk
JOIN promotion p_web
    ON ws.ws_promo_sk = p_web.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm_web
    ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
JOIN warehouse wh_web
    ON ws.ws_warehouse_sk = wh_web.w_warehouse_sk
JOIN household_demographics hd_web_bill
    ON ws.ws_bill_hdemo_sk = hd_web_bill.hd_demo_sk
JOIN household_demographics hd_web_ship
    ON ws.ws_ship_hdemo_sk = hd_web_ship.hd_demo_sk
JOIN customer_address ca_web_bill
    ON ws.ws_bill_addr_sk = ca_web_bill.ca_address_sk
JOIN customer_address ca_web_ship
    ON ws.ws_ship_addr_sk = ca_web_ship.ca_address_sk
WHERE cc.cc_city = 'Shiloh'
  AND s.s_state = 'CA'
  AND p_cat.p_discount_active = 'Y'
  AND wp.wp_rec_end_date >= DATE '2001-01-01'
  AND ws_site.web_rec_start_date <= DATE '2002-12-31'
  AND ib.ib_lower_bound >= 50000
  AND cs_agg.cs_total_sales > 1000
GROUP BY p_cat.p_promo_name,
         cc.cc_name,
         cp.cp_department,
         s.s_store_name,
         ws_site.web_name
HAVING SUM(cs_agg.cs_total_sales) > 5000
ORDER BY catalog_sales_total DESC
LIMIT 100
