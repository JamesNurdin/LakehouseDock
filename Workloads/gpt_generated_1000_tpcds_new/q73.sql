SELECT i_class,
       sm_type,
       birth_month,
       total_profit,
       total_sales,
       avg_inventory
FROM (
        SELECT i.i_class            AS i_class,
               sm.sm_type           AS sm_type,
               c_bill.c_birth_month AS birth_month,
               SUM(ws.ws_net_profit)          AS total_profit,
               SUM(ws.ws_ext_sales_price)     AS total_sales,
               AVG(inv.inv_quantity_on_hand)  AS avg_inventory
        FROM   web_sales ws
               JOIN item i ON ws.ws_item_sk = i.i_item_sk
               JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
               JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
               JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
               JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
               JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
               JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
               JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
               JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
               JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE  c_bill.c_birth_month % 2 = 0
        GROUP BY CUBE (i.i_class, sm.sm_type, c_bill.c_birth_month)
     )
UNION DISTINCT
SELECT i_class,
       sm_type,
       birth_month,
       total_profit,
       total_sales,
       avg_inventory
FROM (
        SELECT i.i_class            AS i_class,
               sm.sm_type           AS sm_type,
               c_bill.c_birth_month AS birth_month,
               SUM(ws.ws_net_profit)          AS total_profit,
               SUM(ws.ws_ext_sales_price)     AS total_sales,
               AVG(inv.inv_quantity_on_hand)  AS avg_inventory
        FROM   web_sales ws
               JOIN item i ON ws.ws_item_sk = i.i_item_sk
               JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
               JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
               JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
               JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
               JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
               JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
               JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
               JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
               JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE  c_bill.c_birth_month % 2 = 1
        GROUP BY CUBE (i.i_class, sm.sm_type, c_bill.c_birth_month)
     )
ORDER BY total_profit DESC
LIMIT 100
