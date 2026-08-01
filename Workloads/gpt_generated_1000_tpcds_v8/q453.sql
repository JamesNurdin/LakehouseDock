WITH base AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_sold_date_sk,
       ss.ss_quantity,
       ss.ss_ext_sales_price,
       ss.ss_ext_tax,
       i.i_item_id,
       i.i_category,
       i.i_brand,
       i.i_current_price,
       ca.ca_state,
       ca.ca_city,
       td.t_time,
       td.t_am_pm,
       ws.ws_order_number,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       w.w_warehouse_name,
       w.w_state,
       wp.wp_type,
       inv.inv_quantity_on_hand,
       ARRAY[ss.ss_quantity, ws.ws_quantity] AS qty_array
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE td.t_am_pm = 'PM'
     AND td.t_time BETWEEN 7 AND 19
     AND i.i_current_price > 50
     AND w.w_state = 'CA'
     AND ss.ss_ext_tax > 100
     AND inv.inv_quantity_on_hand < 200
     AND ws.ws_net_profit > 0
     AND ws.ws_ext_sales_price > 500
),
 ticket_set_a AS (
   SELECT ss_ticket_number AS ticket
   FROM store_sales
   WHERE ss_ext_sales_price > 1000
 ),
 ticket_set_b AS (
   SELECT ws_order_number AS ticket
   FROM web_sales
   WHERE ws_ext_sales_price > 1000
 ),
 common_tickets AS (
   SELECT ticket FROM ticket_set_a
   INTERSECT
   SELECT ticket FROM ticket_set_b
 ),
 filtered AS (
   SELECT
       b.ss_ticket_number,
       b.ca_state,
       b.ca_city,
       b.i_category,
       b.ss_ext_sales_price,
       b.ws_ext_sales_price,
       b.w_state,
       b.qty_array
   FROM base b
   JOIN common_tickets ct ON ct.ticket = b.ss_ticket_number
   WHERE EXISTS (
       SELECT 1
       FROM store_returns sr2
       WHERE sr2.sr_ticket_number = b.ss_ticket_number
         AND sr2.sr_return_amt > 0
   )
 )
SELECT
   f.ca_state,
   f.ca_city,
   f.i_category,
   SUM(f.ss_ext_sales_price) AS store_sales_total,
   SUM(f.ws_ext_sales_price) AS web_sales_total,
   RANK() OVER (PARTITION BY f.i_category ORDER BY SUM(f.ss_ext_sales_price) DESC) AS category_sales_rank,
   CASE WHEN MAX(f.w_state) = 'CA' THEN 'West Coast' ELSE 'Other' END AS region_flag,
   qty
FROM filtered f
CROSS JOIN UNNEST(f.qty_array) AS t(qty)
GROUP BY ROLLUP (f.ca_state, f.ca_city, f.i_category, qty)
ORDER BY store_sales_total DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
