WITH inv_agg AS (
   SELECT inv_date_sk,
          SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory
   WHERE inv_quantity_on_hand > 0
   GROUP BY inv_date_sk
),
union_returns AS (
   SELECT cr.cr_returned_date_sk,
          cr.cr_return_quantity,
          cr.cr_return_amount,
          cr.cr_reason_sk,
          cr.cr_catalog_page_sk,
          cr.cr_refunded_customer_sk,
          cr.cr_returning_customer_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001 AND d.d_month_seq = 1
   UNION ALL
   SELECT cr.cr_returned_date_sk,
          cr.cr_return_quantity,
          cr.cr_return_amount,
          cr.cr_reason_sk,
          cr.cr_catalog_page_sk,
          cr.cr_refunded_customer_sk,
          cr.cr_returning_customer_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2002 AND d.d_month_seq = 12
)
SELECT
   d.d_year,
   d.d_month_seq,
   cp.cp_department,
   r.r_reason_desc,
   COUNT(DISTINCT u.cr_returning_customer_sk) AS distinct_returning_customers,
   SUM(u.cr_return_quantity) AS total_return_qty,
   SUM(u.cr_return_amount) AS total_return_amount,
   SUM(CASE WHEN r.r_reason_desc LIKE '%color%' THEN u.cr_return_amount ELSE 0 END) AS color_related_return_amount,
   SUM(i.total_qty_on_hand) AS total_inventory_on_hand,
   COUNT(DISTINCT w.wp_web_page_sk) AS web_pages_touched
FROM union_returns u
JOIN date_dim d ON u.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON u.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON u.cr_reason_sk = r.r_reason_sk
JOIN inv_agg i ON i.inv_date_sk = d.d_date_sk
JOIN customer c_refund ON u.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer c_return ON u.cr_returning_customer_sk = c_return.c_customer_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page w ON w.wp_customer_sk = c_return.c_customer_sk
WHERE c_return.c_birth_country = 'United States'
  AND cp.cp_type = 'Standard'
  AND r.r_reason_id = 'AAAAAAAACBAAAAAA'
  AND s.s_state = 'CA'
GROUP BY d.d_year, d.d_month_seq, cp.cp_department, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
