WITH sel1 AS (
    SELECT
        cd.cd_gender,
        i.i_category,
        td.t_hour,
        cs.cs_ext_sales_price               AS cs_sales,
        ss.ss_net_paid                       AS ss_paid,
        ws.ws_net_paid                       AS ws_paid,
        inv.inv_quantity_on_hand             AS inv_qty,
        c.c_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cs.cs_ext_sales_price DESC) AS gender_rank
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_customer_sk = c.c_customer_sk
     AND ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE p.p_channel_email = 'Y'
      AND c.c_customer_sk IN (
          SELECT c2.c_customer_sk
          FROM customer c2
          WHERE c2.c_preferred_cust_flag = 'Y'
      )
      AND i.i_item_sk IN (
          SELECT inv_item_sk FROM inventory
          INTERSECT
          SELECT p_item_sk FROM promotion
      )
      AND cs.cs_ext_sales_price > (
          SELECT avg(p2.p_cost)
          FROM promotion p2
          WHERE p2.p_discount_active = 'Y'
      )
),
sel2 AS (
    SELECT
        cd.cd_gender,
        i.i_category,
        td.t_hour,
        cs.cs_ext_sales_price               AS cs_sales,
        ss.ss_net_paid                       AS ss_paid,
        ws.ws_net_paid                       AS ws_paid,
        inv.inv_quantity_on_hand             AS inv_qty,
        c.c_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cs.cs_ext_sales_price DESC) AS gender_rank
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_customer_sk = c.c_customer_sk
     AND ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE p.p_channel_tv = 'Y'
      AND c.c_customer_sk IN (
          SELECT c2.c_customer_sk
          FROM customer c2
          WHERE c2.c_preferred_cust_flag = 'Y'
      )
      AND i.i_item_sk IN (
          SELECT inv_item_sk FROM inventory
          INTERSECT
          SELECT p_item_sk FROM promotion
      )
      AND cs.cs_ext_sales_price > (
          SELECT avg(p2.p_cost)
          FROM promotion p2
          WHERE p2.p_discount_active = 'Y'
      )
),
combined AS (
    SELECT * FROM sel1
    UNION
    SELECT * FROM sel2
)
SELECT
    cd_gender,
    i_category,
    t_hour,
    SUM(cs_sales)   AS total_cs_sales,
    SUM(ss_paid)    AS total_ss_paid,
    SUM(ws_paid)    AS total_ws_paid,
    SUM(inv_qty)    AS total_inventory_qty,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers
FROM combined
GROUP BY ROLLUP (cd_gender, i_category, t_hour)
ORDER BY cd_gender, i_category, t_hour
LIMIT 100
