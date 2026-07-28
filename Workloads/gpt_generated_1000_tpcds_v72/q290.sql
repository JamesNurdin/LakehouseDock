WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_paid,
       ss.ss_net_paid,
       ws.ws_net_paid,
       s.s_store_name,
       s.s_state,
       p.p_promo_name,
       r.r_reason_desc
   FROM tpcds.catalog_sales cs
   JOIN tpcds.call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN tpcds.warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN tpcds.customer_address ca
     ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN tpcds.catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
   JOIN tpcds.reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN tpcds.store_sales ss
     ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_promo_sk = p.p_promo_sk
    AND ss.ss_hdemo_sk = hd.hd_demo_sk
    AND ss.ss_addr_sk = ca.ca_address_sk
   JOIN tpcds.store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN tpcds.web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_promo_sk = p.p_promo_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE cc.cc_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND cp.cp_catalog_page_number = 19
     AND s.s_state = 'CA'
     AND ca.ca_county = 'Williams County'
     AND EXISTS (
         SELECT 1 FROM tpcds.store s2
         WHERE s2.s_store_sk = s.s_store_sk
           AND s2.s_floor_space > 9000000
     )
)
SELECT
    s_store_name,
    s_state,
    p_promo_name,
    r_reason_desc,
    SUM(cs_net_paid) AS catalog_sales_net,
    SUM(ss_net_paid) AS store_sales_net,
    SUM(ws_net_paid) AS web_sales_net,
    COUNT(DISTINCT cs_order_number) AS num_orders
FROM base
GROUP BY
    s_store_name,
    s_state,
    p_promo_name,
    r_reason_desc
ORDER BY catalog_sales_net DESC
LIMIT 100
