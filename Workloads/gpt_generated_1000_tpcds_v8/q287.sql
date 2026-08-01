WITH sales_agg AS (
   SELECT
       ws.ss_sold_date_sk,
       ws.ss_ticket_number,
       ws.ss_store_sk,
       ws.ss_item_sk,
       SUM(ws.ss_net_paid) AS total_store_net_paid,
       COUNT(*) AS store_txn_cnt
   FROM store_sales ws
   JOIN date_dim d ON ws.ss_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON ws.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ss_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND cd.cd_gender = 'F'
     AND hd.hd_income_band_sk BETWEEN 3 AND 5
     AND ws.ss_quantity > 1
   GROUP BY ws.ss_sold_date_sk, ws.ss_ticket_number, ws.ss_store_sk, ws.ss_item_sk
)

SELECT
   d.d_year,
   sa.ss_store_sk,
   cp.cp_department,
   sm.sm_type,
   w.w_warehouse_name,
   sa.total_store_net_paid,
   SUM(cs.cs_net_paid) AS total_catalog_net_paid,
   COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
   CASE
       WHEN sr.sr_return_quantity IS NULL THEN 'No Return'
       ELSE 'Returned'
   END AS return_flag,
   SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
   sa.store_txn_cnt
FROM sales_agg sa
JOIN store_sales ss ON ss.ss_ticket_number = sa.ss_ticket_number
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
FULL OUTER JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_site we ON we.web_open_date_sk = d.d_date_sk
LEFT JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
WHERE EXISTS (
    SELECT 1 FROM web_site we2
    WHERE we2.web_zip = '48059'
      AND we2.web_state = we.web_state
      AND we2.web_company_id = 3
)
  AND we.web_country = 'United States'
  AND cp.cp_type = 'CATALOG'
  AND sm.sm_carrier = 'UPS'
  AND w.w_city = 'Seattle'
GROUP BY d.d_year,
         sa.ss_store_sk,
         cp.cp_department,
         sm.sm_type,
         w.w_warehouse_name,
         sa.total_store_net_paid,
         CASE
             WHEN sr.sr_return_quantity IS NULL THEN 'No Return'
             ELSE 'Returned'
         END,
         sa.store_txn_cnt
ORDER BY sa.total_store_net_paid DESC
LIMIT 100
