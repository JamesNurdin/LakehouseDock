WITH inventory_agg AS (
       SELECT inv_item_sk,
              inv_warehouse_sk,
              SUM(inv_quantity_on_hand) AS total_qty_on_hand
       FROM inventory
       WHERE inv_date_sk BETWEEN 2450800 AND 2451100
       GROUP BY inv_item_sk, inv_warehouse_sk
   ),
   store_ret AS (
       SELECT sr.sr_reason_sk,
              sr.sr_store_sk,
              sr.sr_item_sk,
              sr.sr_customer_sk,
              sr.sr_addr_sk,
              SUM(sr.sr_net_loss) AS store_net_loss,
              COUNT(*) AS store_ret_cnt
       FROM store_returns sr
       JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
       WHERE d_sr.d_year = 2001
         AND d_sr.d_month_seq BETWEEN 12 AND 15
       GROUP BY sr.sr_reason_sk, sr.sr_store_sk, sr.sr_item_sk, sr.sr_customer_sk, sr.sr_addr_sk
   ),
   catalog_ret AS (
       SELECT cr.cr_reason_sk,
              cr.cr_call_center_sk,
              cr.cr_catalog_page_sk,
              cr.cr_warehouse_sk,
              cr.cr_item_sk,
              cr.cr_refunded_customer_sk,
              cr.cr_refunded_addr_sk,
              SUM(cr.cr_net_loss) AS catalog_net_loss,
              COUNT(*) AS catalog_ret_cnt
       FROM catalog_returns cr
       JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
       WHERE d_cr.d_year = 2001
         AND cr.cr_fee > 20.00
       GROUP BY cr.cr_reason_sk, cr.cr_call_center_sk, cr.cr_catalog_page_sk,
                cr.cr_warehouse_sk, cr.cr_item_sk,
                cr.cr_refunded_customer_sk, cr.cr_refunded_addr_sk
   ),
   web_ret AS (
       SELECT wr.wr_reason_sk,
              wr.wr_web_page_sk,
              wr.wr_item_sk,
              wr.wr_refunded_customer_sk,
              wr.wr_refunded_addr_sk,
              SUM(wr.wr_net_loss) AS web_net_loss,
              COUNT(*) AS web_ret_cnt
       FROM web_returns wr
       JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
       WHERE d_wr.d_year = 2001
         AND wr.wr_return_quantity > 1
       GROUP BY wr.wr_reason_sk, wr.wr_web_page_sk,
                wr.wr_item_sk, wr.wr_refunded_customer_sk,
                wr.wr_refunded_addr_sk
   ),
   common_reasons AS (
       SELECT sr_reason_sk AS reason_sk FROM store_ret
       INTERSECT
       SELECT cr_reason_sk FROM catalog_ret
   )
SELECT
       r.r_reason_desc,
       cc.cc_name,
       cp.cp_description,
       s.s_store_name,
       wp.wp_url,
       i.i_product_name,
       w.w_warehouse_name,
       SUM(sr.store_net_loss) AS total_store_loss,
       SUM(cr.catalog_net_loss) AS total_catalog_loss,
       SUM(wr.web_net_loss) AS total_web_loss,
       SUM(sr.store_ret_cnt) + SUM(cr.catalog_ret_cnt) + SUM(wr.web_ret_cnt) AS total_returns,
       CASE WHEN inv.total_qty_on_hand > 1000 THEN 'High' ELSE 'Low' END AS inventory_level
FROM common_reasons crs
JOIN store_ret sr ON sr.sr_reason_sk = crs.reason_sk
JOIN catalog_ret cr ON cr.cr_reason_sk = crs.reason_sk
JOIN web_ret wr ON wr.wr_reason_sk = crs.reason_sk
JOIN reason r ON r.r_reason_sk = crs.reason_sk
JOIN store s ON s.s_store_sk = sr.sr_store_sk
JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN item i ON i.i_item_sk = sr.sr_item_sk
JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN inventory_agg inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
WHERE EXISTS (
        SELECT 1 FROM date_dim d
        WHERE d.d_date = DATE '2001-06-15' AND d.d_year = 2001
      )
GROUP BY
       r.r_reason_desc,
       cc.cc_name,
       cp.cp_description,
       s.s_store_name,
       wp.wp_url,
       i.i_product_name,
       w.w_warehouse_name,
       inv.total_qty_on_hand,
       CASE WHEN inv.total_qty_on_hand > 1000 THEN 'High' ELSE 'Low' END
ORDER BY total_store_loss DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
