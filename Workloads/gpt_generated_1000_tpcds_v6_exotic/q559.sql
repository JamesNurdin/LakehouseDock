WITH page_returns AS (
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_department,
       r.r_reason_desc,
       i.i_item_desc,
       c.c_email_address,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt,
       AVG(cr.cr_return_amount) AS avg_return_amount
   FROM catalog_returns cr
   JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE regexp_like(i.i_item_desc, '(?i)portable')
     AND c.c_email_address LIKE '%@gmail.com'
   GROUP BY cp.cp_catalog_page_id, cp.cp_department, r.r_reason_desc, i.i_item_desc, c.c_email_address
)
SELECT
   pr.cp_catalog_page_id,
   pr.cp_department,
   pr.r_reason_desc,
   pr.i_item_desc,
   regexp_extract(pr.c_email_address, '^([^@]+)') AS email_username,
   concat(pr.c_email_address, '_', pr.cp_catalog_page_id) AS email_page_key,
   pr.total_return_amount,
   pr.return_cnt,
   pr.avg_return_amount,
   CASE WHEN pr.total_return_amount > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
   (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_return
FROM page_returns pr
WHERE pr.total_return_amount > (
        SELECT AVG(cr3.cr_return_amount) FROM catalog_returns cr3
   )
ORDER BY pr.total_return_amount DESC
LIMIT 100
