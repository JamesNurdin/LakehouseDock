WITH inv_agg AS (
   SELECT inv_item_sk,
          inv_warehouse_sk,
          SUM(inv_quantity_on_hand) AS total_on_hand
   FROM inventory
   JOIN date_dim d_inv ON inv_date_sk = d_inv.d_date_sk
   WHERE d_inv.d_year = 2001
   GROUP BY inv_item_sk, inv_warehouse_sk
),
store_only_items AS (
   SELECT ss.ss_item_sk AS item_sk
   FROM store_sales ss
   WHERE ss.ss_quantity > 0
   EXCEPT
   SELECT ws.ws_item_sk AS item_sk
   FROM web_sales ws
   WHERE ws.ws_quantity > 0
)
SELECT
   d_store.d_year,
   i.i_category,
   w.w_city,
   web.web_site_id,
   COUNT(DISTINCT ss.ss_ticket_number)            AS store_txn_cnt,
   SUM(ss.ss_net_paid)                           AS store_net_paid,
   SUM(cs.cs_net_paid)                           AS catalog_net_paid,
   SUM(ws.ws_net_paid)                           AS web_net_paid,
   CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Medium' END AS store_sales_level,
   inv_agg.total_on_hand,
   COUNT(DISTINCT c.c_customer_sk)               AS distinct_customers,
   AVG(CASE WHEN r.r_reason_desc = 'Damaged' THEN cr.cr_return_amount END) AS avg_damaged_return_amount
FROM store_only_items soi
JOIN store_sales ss            ON soi.item_sk = ss.ss_item_sk
JOIN date_dim d_store          ON ss.ss_sold_date_sk = d_store.d_date_sk
JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs          ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs_sold        ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws              ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws_sold        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web              ON ws.ws_web_site_sk = web.web_site_sk
JOIN inv_agg                   ON inv_agg.inv_item_sk = i.i_item_sk
                                 AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE d_store.d_year = 2001
  AND i.i_category = 'Sports'
  AND w.w_city = 'Riverside'
  AND web.web_market_manager = 'Gilbert Chapman'
  AND cc.cc_class = 'A'
  AND r.r_reason_desc = 'Damaged'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 0
      )
GROUP BY d_store.d_year,
         i.i_category,
         w.w_city,
         web.web_site_id,
         inv_agg.total_on_hand
HAVING SUM(ss.ss_net_paid) > 50000
ORDER BY d_store.d_year, i.i_category
