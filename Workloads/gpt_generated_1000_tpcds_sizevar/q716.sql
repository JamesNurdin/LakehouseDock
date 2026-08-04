WITH item_dim AS (
       SELECT i_item_sk, i_category, i_brand, i_current_price, i_item_id
       FROM item
       WHERE i_current_price > 100
   ),
   cs_not_ws AS (
       SELECT cs_order_number
       FROM catalog_sales
       EXCEPT
       SELECT ws_order_number
       FROM web_sales
   )
SELECT
   cs.cs_order_number,
   cs.cs_net_profit,
   SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
   SUM(ss.ss_ext_sales_price) AS store_sales_total,
   SUM(ws.ws_ext_sales_price) AS web_sales_total,
   COUNT(DISTINCT c1.c_customer_id) AS distinct_customers,
   COUNT(DISTINCT i1.i_item_id) AS distinct_items,
   CASE WHEN cnw.cs_order_number IS NOT NULL THEN 1 ELSE 0 END AS catalog_not_in_web
FROM catalog_sales cs
JOIN customer c1
  ON cs.cs_bill_customer_sk = c1.c_customer_sk
JOIN customer_demographics cd1
  ON cs.cs_bill_cdemo_sk = cd1.cd_demo_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item_dim i1
  ON cs.cs_item_sk = i1.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = i1.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_sales ss
  ON ss.ss_item_sk = i1.i_item_sk
     AND ss.ss_customer_sk = c1.c_customer_sk
LEFT JOIN customer c2
  ON ss.ss_customer_sk = c2.c_customer_sk
LEFT JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = i1.i_item_sk
     AND ws.ws_bill_customer_sk = c1.c_customer_sk
LEFT JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
FULL OUTER JOIN web_returns wr
  ON wr.wr_order_number = cs.cs_order_number
FULL OUTER JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN customer c3
  ON wr.wr_refunded_customer_sk = c3.c_customer_sk
LEFT JOIN cs_not_ws cnw
  ON cnw.cs_order_number = cs.cs_order_number
GROUP BY cs.cs_order_number, cs.cs_net_profit, cnw.cs_order_number
ORDER BY cs.cs_order_number
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
