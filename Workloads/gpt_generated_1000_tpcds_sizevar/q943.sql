WITH
  sr_full AS (
    SELECT sr.*, r.r_reason_desc
    FROM store_returns sr
    FULL OUTER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  ),
  cr_full AS (
    SELECT cr.*, r.r_reason_desc AS cr_reason_desc, cs.cs_item_sk, cs.cs_order_number
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
  ),
  inv_full AS (
    SELECT inv.*, w.w_warehouse_name
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  )
SELECT
  s.s_store_name,
  p.p_promo_name,
  COUNT(DISTINCT ss.ss_customer_sk)               AS distinct_customers,
  SUM(DISTINCT cs.cs_quantity)                    AS distinct_catalog_quantity,
  AVG(ss.ss_net_paid)                             AS avg_net_paid,
  COUNT(*) FILTER (WHERE sr_full.sr_ticket_number IS NULL) AS sales_without_returns,
  (
    SELECT COUNT(*)
    FROM (
      SELECT ss_ticket_number FROM store_sales
      EXCEPT
      SELECT sr_ticket_number FROM store_returns
    ) AS diff
  ) AS sales_not_returned_count
FROM store_sales ss
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN sr_full ON sr_full.sr_ticket_number = ss.ss_ticket_number
JOIN cr_full ON cr_full.cs_order_number = cs.cs_order_number
JOIN inv_full ON inv_full.inv_warehouse_sk = w.w_warehouse_sk
WHERE td.t_am_pm = 'PM'
  AND cd.cd_education_status = 'Advanced Degree'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
      )
GROUP BY s.s_store_name, p.p_promo_name
ORDER BY avg_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
