WITH cs_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        sm.sm_code,
        sm.sm_contract
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_catalog_number IN (4, 15)
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND sm.sm_code = 'AIR'
      AND p.p_discount_active = 'Y'
      AND cs.cs_ext_ship_cost > 100
      AND cs.cs_quantity <= 10
)
SELECT
    ws.ws_web_site_sk,
    ws_site.web_name,
    csf.cp_department,
    csf.cp_catalog_number,
    csf.p_promo_name,
    csf.sm_code,
    COUNT(DISTINCT csf.cs_order_number) AS catalog_order_cnt,
    SUM(csf.cs_ext_sales_price) AS catalog_sales,
    SUM(csf.cs_net_profit) AS catalog_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(ws.ws_net_profit) AS web_profit,
    AVG(ws.ws_quantity) AS avg_web_quantity,
    MIN(ws.ws_ext_sales_price) AS min_web_sale,
    MAX(ws.ws_ext_sales_price) AS max_web_sale
FROM cs_filtered csf
JOIN web_sales ws
    ON ws.ws_promo_sk = csf.cs_promo_sk
   AND ws.ws_ship_mode_sk = csf.cs_ship_mode_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE ws.ws_quantity > 5
  AND ws.ws_net_paid > 200
  AND ws_site.web_state = 'CA'
  AND ws_site.web_gmt_offset BETWEEN -8.0 AND -5.0
GROUP BY
    ws.ws_web_site_sk,
    ws_site.web_name,
    csf.cp_department,
    csf.cp_catalog_number,
    csf.p_promo_name,
    csf.sm_code
ORDER BY catalog_sales DESC
LIMIT 100
