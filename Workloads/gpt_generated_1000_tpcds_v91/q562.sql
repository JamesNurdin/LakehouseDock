WITH cat AS (
    SELECT
        COALESCE(cs.cs_order_number, cr.cr_order_number) AS order_number,
        COALESCE(cs.cs_sold_time_sk, cr.cr_returned_time_sk) AS time_sk,
        COALESCE(cs.cs_item_sk, cr.cr_item_sk) AS item_sk,
        COALESCE(cs.cs_call_center_sk, cr.cr_call_center_sk) AS call_center_sk,
        COALESCE(cs.cs_catalog_page_sk, cr.cr_catalog_page_sk) AS catalog_page_sk,
        COALESCE(cs.cs_ship_mode_sk, cr.cr_ship_mode_sk) AS ship_mode_sk,
        COALESCE(cs.cs_warehouse_sk, cr.cr_warehouse_sk) AS warehouse_sk,
        COALESCE(cs.cs_bill_customer_sk, cs.cs_ship_customer_sk, cr.cr_refunded_customer_sk, cr.cr_returning_customer_sk) AS customer_sk,
        COALESCE(cs.cs_bill_hdemo_sk, cs.cs_ship_hdemo_sk, cr.cr_refunded_hdemo_sk, cr.cr_returning_hdemo_sk) AS hdemo_sk,
        COALESCE(cs.cs_bill_addr_sk, cs.cs_ship_addr_sk, cr.cr_refunded_addr_sk, cr.cr_returning_addr_sk) AS addr_sk,
        COALESCE(cs.cs_ext_sales_price, 0) AS cat_sales,
        COALESCE(cr.cr_return_amount, 0) AS cat_return_amount,
        COALESCE(cs.cs_net_profit, 0) AS cat_net_profit,
        COALESCE(cr.cr_net_loss, 0) AS cat_net_loss
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
)
SELECT
    t.t_hour,
    i_cat.i_category,
    cc.cc_name,
    cp.cp_department,
    ws_site.web_name,
    sm_cross.sm_code,
    pset.promo_code,
    SUM(cat.cat_sales) AS total_catalog_sales,
    SUM(cat.cat_return_amount) AS total_catalog_returns,
    SUM(ss.ss_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(ws.ws_sales_price) AS total_web_sales,
    SUM(cat.cat_net_profit) AS total_catalog_net_profit,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit
FROM cat
JOIN call_center cc ON cc.cc_call_center_sk = cat.call_center_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cat.catalog_page_sk
JOIN item i_cat ON i_cat.i_item_sk = cat.item_sk
JOIN ship_mode sm_cat ON sm_cat.sm_ship_mode_sk = cat.ship_mode_sk
JOIN warehouse w_cat ON w_cat.w_warehouse_sk = cat.warehouse_sk
JOIN time_dim t ON t.t_time_sk = cat.time_sk
LEFT JOIN customer c ON c.c_customer_sk = cat.customer_sk
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cat.hdemo_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = cat.addr_sk
LEFT JOIN store_sales ss
    ON ss.ss_sold_time_sk = cat.time_sk
   AND ss.ss_item_sk = cat.item_sk
   AND ss.ss_customer_sk = cat.customer_sk
LEFT JOIN item i_store ON i_store.i_item_sk = ss.ss_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = cat.time_sk
   AND sr.sr_item_sk = cat.item_sk
   AND sr.sr_customer_sk = cat.customer_sk
LEFT JOIN item i_return_item ON i_return_item.i_item_sk = sr.sr_item_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = cat.time_sk
   AND ws.ws_item_sk = cat.item_sk
   AND ws.ws_bill_customer_sk = cat.customer_sk
LEFT JOIN web_site ws_site ON ws_site.web_site_sk = ws.ws_web_site_sk
LEFT JOIN item i_web ON i_web.i_item_sk = ws.ws_item_sk
CROSS JOIN ship_mode sm_cross
CROSS JOIN (SELECT 'PROMO1' AS promo_code UNION ALL SELECT 'PROMO2' AS promo_code) pset
GROUP BY
    t.t_hour,
    i_cat.i_category,
    cc.cc_name,
    cp.cp_department,
    ws_site.web_name,
    sm_cross.sm_code,
    pset.promo_code
ORDER BY total_catalog_sales DESC
LIMIT 100
