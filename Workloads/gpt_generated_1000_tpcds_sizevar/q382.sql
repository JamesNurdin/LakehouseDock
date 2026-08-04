WITH cs AS (
   SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_bill_customer_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_net_paid,
      cs.cs_quantity
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
cr AS (
   SELECT
      cr.cr_order_number,
      cr.cr_returned_date_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount
   FROM catalog_returns cr
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
   JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
),
ws AS (
   SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_bill_customer_sk,
      ws.ws_web_page_sk,
      ws.ws_ship_mode_sk,
      ws.ws_net_paid,
      ws.ws_quantity
   FROM web_sales ws
   JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
   JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN ship_mode sm3 ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
),
wr AS (
   SELECT
      wr.wr_order_number,
      wr.wr_returned_date_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt
   FROM web_returns wr
   JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
   JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
   JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
),
sr AS (
   SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt
   FROM store_returns sr
   JOIN date_dim d4 ON sr.sr_returned_date_sk = d4.d_date_sk
   JOIN reason r3 ON sr.sr_reason_sk = r3.r_reason_sk
   JOIN customer c3 ON sr.sr_customer_sk = c3.c_customer_sk
),
order_exceptions AS (
   SELECT cs_order_number AS order_number FROM cs
   EXCEPT
   SELECT cr_order_number FROM cr
),
full_returns AS (
   SELECT
      sr.sr_ticket_number AS return_id,
      sr.sr_returned_date_sk AS return_date_sk,
      sr.sr_return_quantity AS qty,
      'store' AS source
   FROM sr
   UNION ALL
   SELECT
      wr.wr_order_number AS return_id,
      wr.wr_returned_date_sk AS return_date_sk,
      wr.wr_return_quantity AS qty,
      'web' AS source
   FROM wr
),
combined AS (
   SELECT
      d.d_year,
      COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_orders,
      COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
      SUM(CASE WHEN cs.cs_net_paid > 1000 THEN cs.cs_net_paid ELSE 0 END) AS high_value_catalog_sales,
      SUM(CASE WHEN ws.ws_net_paid > 1000 THEN ws.ws_net_paid ELSE 0 END) AS high_value_web_sales
   FROM cs
   JOIN ws ON cs.cs_bill_customer_sk = ws.ws_bill_customer_sk
   LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   FULL OUTER JOIN full_returns fr ON d.d_date_sk = fr.return_date_sk
   GROUP BY d.d_year
)
SELECT *
FROM combined
WHERE d_year IS NOT NULL
ORDER BY d_year DESC
LIMIT 100
