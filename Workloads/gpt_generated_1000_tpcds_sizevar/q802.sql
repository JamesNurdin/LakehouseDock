WITH inv_agg AS (
   SELECT inv_item_sk,
          inv_warehouse_sk,
          SUM(inv_quantity_on_hand) AS total_on_hand
   FROM inventory
   WHERE inv_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
   GROUP BY inv_item_sk, inv_warehouse_sk
),
intersect_keys AS (
   SELECT ss_ticket_number AS ticket
   FROM store_sales
   INTERSECT
   SELECT ws_order_number FROM web_sales
),
active_sales_keys AS (
   SELECT ss_ticket_number
   FROM store_sales
   EXCEPT
   SELECT ss.ss_ticket_number
   FROM store_sales ss
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE p.p_discount_active = 'N'
),
sales_union AS (
   -- Store side
   SELECT
       ss.ss_ticket_number,
       i.i_item_id,
       i.i_product_name,
       c.c_customer_id,
       d.d_year,
       p.p_promo_id,
       w.w_warehouse_name,
       sm.sm_type,
       ss.ss_net_profit,
       inv_agg.total_on_hand,
       cd.cd_education_status,
       r.r_reason_desc,
       cc.cc_name,
       t.t_hour,
       ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ss.ss_net_profit DESC) AS rn,
       'store' AS src
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
   LEFT JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN ship_mode sm ON FALSE   -- no ship mode for store side
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'BrandX'
     AND c.c_birth_country = 'United States'
     AND t.t_hour BETWEEN 9 AND 17
     AND cc.cc_state = 'CA'
   UNION DISTINCT
   -- Web side
   SELECT
       ws.ws_order_number AS ss_ticket_number,
       i.i_item_id,
       i.i_product_name,
       bc.c_customer_id,
       d.d_year,
       p.p_promo_id,
       w.w_warehouse_name,
       sm.sm_type,
       ws.ws_net_profit,
       inv_agg.total_on_hand,
       cd.cd_education_status,
       NULL AS r_reason_desc,
       cc.cc_name,
       t.t_hour,
       ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_net_profit DESC) AS rn,
       'web' AS src
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer bc ON ws.ws_bill_customer_sk = bc.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
   LEFT JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
   WHERE d.d_year = 2001
     AND i.i_color = 'Red'
     AND bc.c_preferred_cust_flag = 'Y'
     AND wp.wp_autogen_flag = 'Y'
     AND wsit.web_mkt_class LIKE '%New%'
     AND t.t_hour BETWEEN 9 AND 17
     AND cc.cc_state = 'CA'
)
SELECT
    su.src,
    su.i_item_id,
    su.i_product_name,
    su.c_customer_id,
    su.d_year,
    su.p_promo_id,
    su.w_warehouse_name,
    su.sm_type,
    su.rn,
    su.ss_net_profit,
    su.total_on_hand,
    su.cd_education_status,
    su.r_reason_desc,
    su.cc_name,
    (SELECT AVG(total_on_hand) FROM inv_agg) AS avg_on_hand,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_ticket_number = su.ss_ticket_number) AS return_count
FROM sales_union su
WHERE su.rn <= 5
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = su.ss_ticket_number
      )
  AND su.ss_ticket_number IN (SELECT ticket FROM intersect_keys)
  AND su.ss_ticket_number IN (SELECT ss_ticket_number FROM active_sales_keys)
ORDER BY su.ss_net_profit DESC
LIMIT 100
