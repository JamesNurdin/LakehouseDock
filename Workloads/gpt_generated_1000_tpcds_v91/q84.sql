WITH catalog_part AS (
   SELECT
      cr.cr_returned_date_sk AS return_date_sk,
      d.d_date AS return_date,
      'catalog' AS return_type,
      i.i_item_id AS item_id,
      i.i_item_desc AS item_desc,
      cr.cr_return_quantity AS quantity,
      cr.cr_net_loss AS net_loss,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
      CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'No Loss' END AS loss_flag,
      ROW_NUMBER() OVER (ORDER BY d.d_date) AS row_num,
      (SELECT avg(cr2.cr_net_loss)
         FROM catalog_returns cr2
         WHERE cr2.cr_item_sk = cr.cr_item_sk) AS avg_item_net_loss,
      w.w_warehouse_name AS location_name,
      r.r_reason_sk AS reason_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2001
     AND i.i_units = 'Bundle'
     AND i.i_manager_id IN (6, 98)
),
store_part AS (
   SELECT
      sr.sr_returned_date_sk AS return_date_sk,
      d.d_date AS return_date,
      'store' AS return_type,
      i.i_item_id AS item_id,
      i.i_item_desc AS item_desc,
      sr.sr_return_quantity AS quantity,
      sr.sr_net_loss AS net_loss,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
      CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'No Loss' END AS loss_flag,
      ROW_NUMBER() OVER (ORDER BY d.d_date) AS row_num,
      (SELECT avg(sr2.sr_net_loss)
         FROM store_returns sr2
         WHERE sr2.sr_item_sk = sr.sr_item_sk) AS avg_item_net_loss,
      s.s_store_name AS location_name,
      r.r_reason_sk AS reason_sk
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE d.d_year = 2001
     AND i.i_units = 'Bundle'
     AND i.i_manager_id IN (6, 98)
)
SELECT
   combined.return_date_sk,
   combined.return_date,
   combined.return_type,
   combined.item_id,
   combined.item_desc,
   combined.quantity,
   combined.net_loss,
   combined.customer_name,
   combined.loss_flag,
   combined.row_num,
   combined.avg_item_net_loss,
   combined.location_name,
   combined.reason_sk
FROM (
   SELECT * FROM catalog_part
   UNION ALL
   SELECT * FROM store_part
) AS combined
WHERE EXISTS (
   SELECT 1
   FROM reason r2
   WHERE r2.r_reason_sk = combined.reason_sk
     AND r2.r_reason_desc LIKE '%defect%'
)
ORDER BY combined.return_date DESC
LIMIT 100
