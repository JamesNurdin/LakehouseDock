WITH joined AS (
   SELECT
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       i.i_item_id,
       i.i_class,
       i.i_units,
       cc.cc_name,
       cp.cp_description,
       p.p_promo_name,
       sm.sm_type,
       w.w_warehouse_name,
       wp.wp_url,
       webs.web_name,
       cs.cs_net_paid AS cs_net_paid,
       ws.ws_net_paid AS ws_net_paid,
       sr.sr_return_amt AS store_return_amt,
       wr.wr_return_amt AS web_return_amt
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
   WHERE i.i_class = 'furniture'
     AND w.w_warehouse_sq_ft > 600000
     AND cc.cc_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND ws.ws_net_paid_inc_tax > 1000
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    i_item_id,
    i_class,
    i_units,
    cc_name,
    cp_description,
    p_promo_name,
    sm_type,
    w_warehouse_name,
    wp_url,
    web_name,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ws_net_paid) AS total_web_net_paid,
    SUM(store_return_amt) AS total_store_return,
    SUM(web_return_amt) AS total_web_return,
    (SUM(cs_net_paid) + SUM(ws_net_paid)) AS total_sales,
    RANK() OVER (ORDER BY (SUM(cs_net_paid) + SUM(ws_net_paid)) DESC) AS sales_rank
FROM joined
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    i_item_id,
    i_class,
    i_units,
    cc_name,
    cp_description,
    p_promo_name,
    sm_type,
    w_warehouse_name,
    wp_url,
    web_name
ORDER BY sales_rank
LIMIT 100
