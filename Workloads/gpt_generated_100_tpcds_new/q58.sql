WITH catalog_items AS (
   SELECT DISTINCT cs.cs_item_sk AS item_sk
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17
),
web_items AS (
   SELECT DISTINCT ws.ws_item_sk AS item_sk
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17
),
common_items AS (
   SELECT ci.item_sk
   FROM catalog_items ci
   INTERSECT
   SELECT wi.item_sk
   FROM web_items wi
)
SELECT
   i.i_item_id,
   i.i_product_name,
   cc.cc_name AS call_center_name,
   cp.cp_department,
   sm_cs.sm_type AS ship_mode_type,
   w.w_warehouse_name,
   r_cr.r_reason_desc AS catalog_return_reason,
   r_sr.r_reason_desc AS store_return_reason,
   r_wr.r_reason_desc AS web_return_reason,
   wp.wp_url AS web_page_url,
   cd.cd_education_status,
   SUM(
       COALESCE(cs.cs_net_profit, 0) +
       COALESCE(ss.ss_net_profit, 0) +
       COALESCE(ws.ws_net_profit, 0) -
       COALESCE(cr.cr_net_loss, 0) -
       COALESCE(sr.sr_net_loss, 0) -
       COALESCE(wr.wr_net_loss, 0)
   ) AS total_net_profit,
   (
       SELECT SUM(inv_quantity_on_hand)
       FROM inventory inv
       WHERE inv.inv_item_sk = i.i_item_sk
   ) AS total_inventory_on_hand
FROM
   common_items ci
   JOIN item i ON i.i_item_sk = ci.item_sk
   LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
   LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
   LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
   LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
   LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
   LEFT JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
   LEFT JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
   LEFT JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
   LEFT JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
   LEFT JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
WHERE
   i.i_item_sk IN (SELECT item_sk FROM common_items)
   AND i.i_color IN ('tan', 'olive')
   AND cc.cc_call_center_sk IN (
       SELECT cs2.cs_call_center_sk
       FROM catalog_sales cs2
       WHERE cs2.cs_quantity > 0
   )
   AND EXISTS (
       SELECT 1
       FROM store_sales ss2
       WHERE ss2.ss_ticket_number = ss.ss_ticket_number
         AND ss2.ss_quantity > 0
   )
GROUP BY
   i.i_item_id,
   i.i_product_name,
   cc.cc_name,
   cp.cp_department,
   sm_cs.sm_type,
   w.w_warehouse_name,
   r_cr.r_reason_desc,
   r_sr.r_reason_desc,
   r_wr.r_reason_desc,
   wp.wp_url,
   cd.cd_education_status,
   i.i_item_sk
ORDER BY
   total_net_profit DESC
LIMIT 100
