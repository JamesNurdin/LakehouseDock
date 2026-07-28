WITH filtered_returns AS (
   SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cr.cr_warehouse_sk,
      cr.cr_catalog_page_sk,
      cr.cr_refunded_customer_sk,
      cr.cr_order_number
   FROM catalog_returns cr
   WHERE cr.cr_return_amount > 500.00
     AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
     AND cr.cr_net_loss > 100.00
),
aggregated AS (
   SELECT
      w.w_warehouse_name,
      cp.cp_department,
      COUNT(DISTINCT fr.cr_order_number) AS num_returns,
      SUM(fr.cr_return_amount) AS total_return_amount,
      AVG(ws.ws_net_profit) AS avg_web_sales_profit,
      (
         SELECT AVG(ws2.ws_ext_tax)
         FROM web_sales ws2
         WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
      ) AS avg_tax_warehouse,
      w.w_warehouse_sk
   FROM filtered_returns fr
   JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON fr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN customer c ON fr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE c.c_birth_month = 6
     AND c.c_birth_day = 20
     AND ws.ws_quantity > 20
   GROUP BY w.w_warehouse_name, cp.cp_department, w.w_warehouse_sk
   HAVING SUM(fr.cr_return_amount) > 1000.00
)
SELECT
   a.w_warehouse_name,
   a.cp_department,
   a.num_returns,
   a.total_return_amount,
   a.avg_web_sales_profit,
   a.avg_tax_warehouse,
   SUM(a.total_return_amount) OVER (PARTITION BY a.w_warehouse_name) AS warehouse_return_amount_total,
   RANK() OVER (ORDER BY a.total_return_amount DESC) AS return_amount_rank
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
