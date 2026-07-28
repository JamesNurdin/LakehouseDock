WITH base AS (
   SELECT
       d1.d_year,
       cc.cc_name AS call_center_name,
       w.w_warehouse_name AS warehouse_name,
       sr.sr_return_amt,
       sr.sr_return_quantity,
       cd.cd_gender,
       cd.cd_marital_status,
       ca.ca_state,
       r.r_reason_desc,
       i.inv_quantity_on_hand,
       wp.wp_type,
       ws.web_name,
       wr.wr_return_amt_inc_tax,
       wr.wr_return_quantity
   FROM store_returns sr
   JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d1.d_date_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN inventory i ON i.inv_date_sk = d1.d_date_sk
   JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc ON cc.cc_closed_date_sk = d1.d_date_sk
   JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk
   WHERE d1.d_year BETWEEN 2000 AND 2002
     AND ca.ca_state IN ('CA','TX','NY')
     AND cd.cd_gender = 'M'
     AND r.r_reason_desc LIKE '%defect%'
     AND i.inv_quantity_on_hand > 0
)
SELECT
   base.d_year,
   base.call_center_name,
   base.warehouse_name,
   base.r_reason_desc,
   SUM(base.sr_return_amt) AS total_store_return_amt,
   SUM(base.wr_return_amt_inc_tax) AS total_web_return_amt_inc_tax,
   COUNT(DISTINCT base.sr_return_quantity) AS distinct_store_return_qty,
   AVG(base.inv_quantity_on_hand) AS avg_inventory_on_hand,
   (SELECT AVG(i3.inv_quantity_on_hand) FROM inventory i3) AS overall_avg_inventory
FROM base
GROUP BY
   base.d_year,
   base.call_center_name,
   base.warehouse_name,
   base.r_reason_desc
HAVING
   SUM(base.sr_return_amt) > 10000
   AND EXISTS (
       SELECT 1 FROM reason r2
       WHERE r2.r_reason_desc = base.r_reason_desc
         AND r2.r_reason_id IS NOT NULL
   )
ORDER BY total_store_return_amt DESC
LIMIT 100
