WITH joined AS (
   SELECT
       cc.cc_name,
       sm.sm_type,
       cs.cs_order_number,
       cs.cs_quantity,
       cs.cs_net_paid,
       ws.ws_order_number,
       ws.ws_quantity,
       ws.ws_net_paid,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       inv.inv_quantity_on_hand,
       p.p_promo_id,
       sm.sm_code,
       cc.cc_rec_start_date
   FROM tpcds.catalog_sales cs
   JOIN tpcds.call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN tpcds.ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.customer_address ca
     ON cs.cs_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN tpcds.catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN tpcds.web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN tpcds.inventory inv
     ON inv.inv_item_sk = i.i_item_sk
   WHERE sm.sm_code = 'AIR'
     AND cc.cc_rec_start_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
     AND cs.cs_quantity > 5
)
SELECT
    cc_name,
    sm_type,
    SUM(cs_net_paid)                AS total_catalog_sales,
    SUM(ws_net_paid)                AS total_web_sales,
    SUM(cs_net_paid) + SUM(ws_net_paid) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws_order_number) AS web_orders,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_net_paid) + SUM(ws_net_paid) DESC) AS sales_rank,
    CASE
        WHEN SUM(cs_net_paid) + SUM(ws_net_paid) > 1000000 THEN 'HIGH'
        WHEN SUM(cs_net_paid) + SUM(ws_net_paid) > 500000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category
FROM joined
GROUP BY ROLLUP (cc_name, sm_type)
ORDER BY total_sales DESC
LIMIT 100
