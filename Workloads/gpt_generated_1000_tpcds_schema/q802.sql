WITH
   inventory_agg AS (
      SELECT inv_item_sk,
             inv_warehouse_sk,
             SUM(inv_quantity_on_hand) AS total_on_hand
      FROM inventory TABLESAMPLE BERNOULLI (10)
      GROUP BY inv_item_sk, inv_warehouse_sk
   ),
   customer_union AS (
      SELECT ss_customer_sk AS cust_sk FROM store_sales
      UNION
      SELECT ws_bill_customer_sk AS cust_sk FROM web_sales
   ),
   order_intersect AS (
      SELECT cs_order_number FROM catalog_sales
      INTERSECT
      SELECT cr_order_number FROM catalog_returns
   ),
   call_center_f AS (
      SELECT cc.cc_call_center_sk,
             cc.cc_name,
             d.d_date
      FROM call_center cc
      JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
      WHERE d.d_year = 2000
   ),
   web_site_f AS (
      SELECT ws.web_site_sk,
             ws.web_name,
             d.d_date
      FROM web_site ws
      JOIN date_dim d ON ws.web_close_date_sk = d.d_date_sk
      WHERE d.d_year = 2000
   )
SELECT
   d.d_year,
   d.d_month_seq,
   c.c_customer_id,
   cd.cd_gender,
   SUM(COALESCE(ss.ss_net_profit, 0)) AS store_profit,
   SUM(COALESCE(cs.cs_net_profit, 0)) AS catalog_profit,
   SUM(COALESCE(ws.ws_net_profit, 0)) AS web_profit,
   SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
   ia.total_on_hand,
   COALESCE(cc_f.cc_name, 'No CC') AS call_center_name,
   COALESCE(ws_f.web_name, 'No Site') AS web_site_name,
   (SELECT SUM(total_on_hand) FROM inventory_agg) AS overall_inventory_qty
FROM
   date_dim d
   JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
   JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
   LEFT JOIN inventory_agg ia ON ia.inv_item_sk = cs.cs_item_sk AND ia.inv_warehouse_sk = cs.cs_warehouse_sk
   LEFT JOIN customer_union cu ON cu.cust_sk = c.c_customer_sk
   LEFT JOIN order_intersect oi ON oi.cs_order_number = cs.cs_order_number
   FULL OUTER JOIN call_center_f cc_f ON cc_f.d_date = d.d_date
   FULL OUTER JOIN web_site_f ws_f ON ws_f.d_date = d.d_date
WHERE
   d.d_year = 2000
   AND c.c_birth_month = 5
GROUP BY
   d.d_year,
   d.d_month_seq,
   c.c_customer_id,
   cd.cd_gender,
   ia.total_on_hand,
   cc_f.cc_name,
   ws_f.web_name
HAVING
   SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) > 10000
ORDER BY
   d.d_year DESC,
   store_profit DESC
LIMIT 100
