WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       cs.cs_quantity,
       cs.cs_net_paid,
       i.i_brand,
       i.i_category,
       c.c_first_name,
       c.c_last_name,
       ca.ca_state,
       p.p_promo_name,
       sm.sm_type,
       w.w_warehouse_name,
       cp.cp_department,
       ws.ws_order_number AS web_order,
       ss.ss_ticket_number AS store_ticket,
       inv.inv_quantity_on_hand,
       wp.wp_type,
       web.web_name
   FROM catalog_sales cs
   JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN store_sales ss      ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN web_sales ws        ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN inventory inv       ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_page wp         ON wp.wp_web_page_sk = ws.ws_web_page_sk
   LEFT JOIN web_site web        ON web.web_site_sk = ws.ws_web_site_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
     AND ca.ca_country = 'United States'
     AND p.p_discount_active = 'Y'
),
full_ship AS (
   SELECT cs.cs_order_number, sm.sm_ship_mode_id
   FROM catalog_sales cs
   FULL OUTER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
intersect_orders AS (
   SELECT cs.cs_order_number FROM catalog_sales cs WHERE cs.cs_quantity > 10
   INTERSECT
   SELECT ss.ss_ticket_number FROM store_sales ss WHERE ss.ss_quantity > 10
),
except_orders AS (
   SELECT cs.cs_order_number FROM catalog_sales cs
   EXCEPT
   SELECT ws.ws_order_number FROM web_sales ws
)
SELECT
   b.cs_order_number,
   b.i_brand,
   b.i_category,
   b.c_first_name,
   b.c_last_name,
   b.ca_state,
   b.p_promo_name,
   b.sm_type,
   b.w_warehouse_name,
   b.cp_department,
   b.inv_quantity_on_hand,
   b.wp_type,
   b.web_name,
   b.cs_quantity,
   b.cs_net_paid,
   RANK() OVER (PARTITION BY b.i_brand ORDER BY b.cs_net_paid DESC) AS brand_net_paid_rank,
   SUM(b.cs_quantity) OVER (
       PARTITION BY b.i_category
       ORDER BY b.cs_sold_date_sk
       ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
   ) AS qty_30day_moving_sum,
   CASE
       WHEN b.cs_quantity > 20 THEN 'Large'
       WHEN b.cs_quantity BETWEEN 10 AND 20 THEN 'Medium'
       ELSE 'Small'
   END AS qty_size_bucket
FROM base b
WHERE b.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
  AND b.cs_order_number NOT IN (SELECT cs_order_number FROM except_orders)
ORDER BY b.cs_net_paid DESC
LIMIT 100
